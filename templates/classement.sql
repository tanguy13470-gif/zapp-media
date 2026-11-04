-- Classement général Star AC' Pronos, recalculé comme dans l'appli (fonction de score du site, règles H).
-- LECTURE SEULE. Renvoie {top: 15 premiers, tous: [{p: pseudo, r: rang, t: total}]}.
-- Les joueurs pris en compte sont ceux de l'appli : approved <> false et non bannis.
with
u as (select id, pseudo, created_at from profiles where approved is distinct from false and banned_at is null),
pr as (select * from primes where kind <> 'intro'),
st as (select * from settings where id = 1),
-- 1) bloc « weekly » des primes terminés ou avec gagnant du battle
wk as (
  select u.id uid, p.number prime, p.kind, p.status,
    ((coalesce(p.no_elimination,false) or coalesce(p.elim_disabled,false)) and coalesce(cardinality(p.eliminated_ids),0)=0) as k,
    (w.elim_candidate_id is not null and w.elim_candidate_id = any(coalesce(p.eliminated_ids,'{}'))) as elim_ok,
    (coalesce(wp.candidate_id, w.winner_candidate_id) is not null and coalesce(wp.candidate_id, w.winner_candidate_id) = any(coalesce(p.winner_ids,'{}'))) as win_ok
  from u cross join pr p
  left join weekly_picks w on w.user_id=u.id and w.prime_number=p.number
  left join winner_picks wp on wp.user_id=u.id and wp.prime_number=p.number
  where p.status='done' or coalesce(cardinality(p.winner_ids),0)>0
),
wk2 as (select *, (p_done and not k and elim_ok) as u_ok from (select *, (kind='regular' and status='done') p_done from wk) x),
-- série d'éliminé·e·s justes : les primes K ne cassent pas et ne comptent pas
wk3 as (
  select *, sum(case when p_done and not k and not u_ok then 1 else 0 end) over (partition by uid order by prime) grp from wk2
),
wk4 as (
  select *, case when u_ok then count(*) filter (where u_ok) over (partition by uid, grp order by prime) else 0 end as t from wk3
),
ev as (
  select uid, prime, 'weekly' blk, 10 pts from wk4 where u_ok
  union all select uid, prime, 'weekly', least(6, 2*(t-1)) from wk4 where u_ok and t>=2
  union all select uid, prime, 'weekly', 5 from wk4 where win_ok
  union all select uid, prime, 'weekly', 3 from wk4 where u_ok and win_ok
  -- 2) nommés
  union all select n.user_id, p.number, 'nominees', 4*x.l + case when x.l=3 then 4 else 0 end
    from pr p join nominee_picks n on n.prime_number=p.number
    cross join lateral (select count(*)::int l from unnest(n.candidate_ids) c where c = any(p.nominee_ids)) x
    where p.kind='regular' and coalesce(cardinality(p.nominee_ids),0)>0 and p.nominee_close_at is not null and now()>=p.nominee_close_at and x.l>0
  -- 3) top 3 des évaluations
  union all select e.user_id, p.number, 'eval', 3*x.a + 2*x.b + case when x.a=3 then 5 else 0 end
    from pr p join eval_picks e on e.prime_number=p.number
    cross join lateral (select count(*) filter (where c = any(p.eval_top_ids))::int a,
                               count(*) filter (where o<=3 and c = p.eval_top_ids[o])::int b
                        from unnest(e.candidate_ids) with ordinality t(c,o)) x
    where p.kind='regular' and coalesce(cardinality(p.eval_top_ids),0)>0 and coalesce(p.eval_close_at,p.nominee_close_at) is not null
      and now()>=coalesce(p.eval_close_at,p.nominee_close_at) and x.a>0
),
ev_u as (select * from ev where uid in (select id from u)),
-- 4) joker ×2 : double les points positifs du bloc
jk as (select j.user_id uid, j.prime_number prime, sum(e.pts) pts from jokers j join ev_u e on e.uid=j.user_id and e.prime=j.prime_number and e.blk=j.block and e.pts>0 group by 1,2,j.block),
-- 5) chouchou : fidélité, immunité, pénalités ; dernier de la classe
cc as (select * from picks where kind='chouchou' and user_id in (select id from u)),
done as (select * from pr where status='done'),
loy0 as (
  select d.number prime, x.* from done d cross join lateral (
    select distinct on (c.user_id) c.user_id uid, c.id pid, c.candidate_id from cc c where c.created_at <= d.picks_close_at order by c.user_id, c.created_at desc, c.id desc) x
  join candidates ca on ca.id=x.candidate_id
  where ca.eliminated_prime is null or ca.eliminated_prime > d.number
),
loy as (select uid, prime, row_number() over (partition by pid order by prime) n, pid, candidate_id from loy0),
imm_at as (
  select p.number, p.immune_ids, case when q.number is null or q.kind='intro' then coalesce((select season_picks_close_at from st), p.picks_close_at) else q.prime_date end at
  from pr p left join primes q on q.number=p.number-1 where coalesce(cardinality(p.immune_ids),0)>0
),
imm as (
  select i.number prime, x.uid from imm_at i cross join lateral (
    select distinct on (c.user_id) c.user_id uid, c.candidate_id from cc c where c.created_at <= i.at order by c.user_id, c.created_at desc, c.id desc) x
  where now() >= i.at and x.candidate_id = any(i.immune_ids)
),
pen as (
  select c.user_id uid, row_number() over (partition by c.user_id order by c.created_at, c.id) e
  from cc c join candidates ca on ca.id=c.candidate_id where ca.eliminated_prime is not null
),
der as (
  select c.user_id uid, greatest(5, 30-3*ca.eliminated_prime) pts from picks c join candidates ca on ca.id=c.candidate_id
  where c.kind='dernier' and ca.eliminated_prime is not null and c.user_id in (select id from u)
),
-- 6) prime complet (assiduité) à partir du prime 4
asg as (
  select u.id uid, p.number prime,
   (case when p.kind='final' then exists(select 1 from winner_picks w where w.user_id=u.id and w.prime_number=p.number)
    else (p.nominee_close_at is null or exists(select 1 from nominee_picks n where n.user_id=u.id and n.prime_number=p.number))
     and (coalesce(p.eval_close_at,p.nominee_close_at) is null or exists(select 1 from eval_picks e where e.user_id=u.id and e.prime_number=p.number))
     and (coalesce(p.elim_disabled,false) or exists(select 1 from weekly_picks w where w.user_id=u.id and w.prime_number=p.number))
     and exists(select 1 from winner_picks w where w.user_id=u.id and w.prime_number=p.number) end) ok
  from u cross join pr p
  where p.number>=4 and now() >= greatest(p.picks_close_at, coalesce(p.winner_close_at,p.picks_close_at), coalesce(p.nominee_close_at,p.picks_close_at), coalesce(p.eval_close_at,p.nominee_close_at,p.picks_close_at))
    and u.created_at < case when p.kind='regular' and p.nominee_close_at is not null then p.nominee_close_at else coalesce(p.winner_close_at,p.picks_close_at) end
),
asg2 as (select *, sum(case when ok then 0 else 1 end) over (partition by uid order by prime) g from asg),
asg3 as (select uid, 2 + least(3, count(*) over (partition by uid, g order by prime) - 1) pts from asg2 where ok),
tot as (
  select uid, sum(pts) pts from (
    select uid, pts from ev_u
    union all select uid, pts from jk
    union all select uid, case when n>=7 then 3 when n>=4 then 2 else 1 end from loy
    union all select l.uid, 50 from loy l join primes p on p.number=l.prime where p.kind='final' and l.candidate_id = any(p.winner_ids)
    union all select uid, 2 from imm
    union all select uid, -5*e from pen
    union all select uid, pts from der
    union all select user_id, 10 from insta_claims where status='approved'
    union all select winner_id, win_pts from duels where status='settled' and winner_id is not null and win_pts>0
    union all select uid, pts from asg3
  ) z group by uid
),
rk as (
  select u.pseudo p, coalesce(t.pts,0)::int t from u left join tot t on t.uid=u.id
),
rk2 as (select p, t, rank() over (order by t desc) r from rk)
select json_build_object(
  'calcule_a', now(),
  'top', (select json_agg(json_build_object('r',r,'p',p,'t',t) order by r, p) from (select * from rk2 order by r, p limit 15) x),
  'tous', (select json_agg(json_build_object('p',p,'r',r,'t',t) order by r, p) from rk2)
) as classement;
