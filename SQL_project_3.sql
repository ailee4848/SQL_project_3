/*Cross_Sell analysis:
Compare one month before and after the change,CTR from the /cart page,AVG product per order,AOV 
and overall revenue per /cart page view*/
create temporary table session_seing_cart
select
case when created_at <'2013-09-25' then 'A.Pre_Cross_Sell'
 when created_at > '2013-01-06' then 'A.Pre_Cross_Sell'
end as time_period,
website_session_id as cart_session_id,
website_pageview_id as cart_pageview_id
from website_pageviews
where created_at between '2013-08-25' and  '2013-10-25' and pageview_url ='/cart';

create temporary table cart_session_seing_anather_cart
select session_seing_cart.time_period,session_seing_cart.cart_session_id,
min(website_pageviews.website_pageview_id) as pv_id_af_cart
from session_seing_cart left join website_pageviews on
website_pageviews.website_session_id = session_seing_cart.cart_session_id
and website_pageviews.website_pageview_id >session_seing_cart.cart_pageview_id
group by session_seing_cart.time_period,session_seing_cart.cart_session_id
having min(website_pageviews.website_pageview_id) is not null;


create temporary table pre_post_sessions_orders
select time_period,cart_session_id,order_id,items_purchased,price_usd
from session_seing_cart inner join orders on
 session_seing_cart.cart_session_id=orders.website_session_id;
 
select
session_seing_cart.time_period,
session_seing_cart.cart_session_id,
case when cart_session_seing_anather_cart.cart_session_id is null then 0 else 1 end as clicked_to_another_page,
case when pre_post_sessions_orders.order_id is null then 0 else 1 end as placed_order,
pre_post_sessions_orders.items_purchased,
pre_post_sessions_orders.price_usd
from session_seing_cart left join cart_session_seing_anather_cart
on session_seing_cart.cart_session_id= cart_session_seing_anather_cart.cart_session_id
left join pre_post_sessions_orders on
session_seing_cart.cart_session_id =pre_post_sessions_orders.cart_session_id
order by cart_session_id;

select time_period,
count(distinct cart_session_id) as sessions,
sum(clicked_to_another_page) as clickthrough,
sum(clicked_to_another_page)/count(distinct cart_session_id) as cart_ctr,
sum(placed_order) as orders_placed,
sum(items_purchased)/sum(placed_order) as products_per_order,
sum(items_purchased) as products_purchased,
sum(price_usd) as revenue,
sum(price_usd)/sum(placed_order) as AOV,
sum(price_usd)/count(distinct cart_session_id) as rev_per_cart_session
from (select 
session_seing_cart.time_period,
session_seing_cart.cart_session_id,
case when cart_session_seing_anather_cart.cart_session_id is null then 0 else 1 end as clicked_to_another_page,
case when pre_post_sessions_orders.order_id is null then 0 else 1 end as placed_order,
pre_post_sessions_orders.items_purchased,
pre_post_sessions_orders.price_usd
from session_seing_cart left join cart_session_seing_anather_cart
on session_seing_cart.cart_session_id= cart_session_seing_anather_cart.cart_session_id
left join pre_post_sessions_orders on
session_seing_cart.cart_session_id =pre_post_sessions_orders.cart_session_id
order by cart_session_id) as full_date
group by time_period;

/* Product Refund Analysis:Pull monthly refund rates,by month*/
select year(order_items.created_at) as yr,
month(order_items.created_at) as mn,
count(distinct case when product_id = 1 then order_items.order_item_id else null end)as p1_orders,
count(distinct case when product_id = 1 then order_item_refunds.order_item_id else null end)/
count(distinct case when product_id = 1 then order_items.order_item_id else null end)as p1_refund_rt,
count(distinct case when product_id = 2 then order_items.order_item_id else null end)as p2_orders,
count(distinct case when product_id = 2 then order_item_refunds.order_item_id else null end)/
count(distinct case when product_id = 2 then order_items.order_item_id else null end)as p2_refund_rt,
count(distinct case when product_id = 3 then order_items.order_item_id else null end)as p3_orders,
count(distinct case when product_id = 3 then order_item_refunds.order_item_id else null end)/
count(distinct case when product_id = 3 then order_items.order_item_id else null end)as p3_refund_rt,
count(distinct case when product_id = 4 then order_items.order_item_id else null end)as p4_orders,
count(distinct case when product_id = 4 then order_item_refunds.order_item_id else null end)/
count(distinct case when product_id = 4 then order_items.order_item_id else null end)as p4_refund_rt
from order_items left join order_item_refunds on
order_items.order_item_id = order_item_refunds.order_item_id
where order_items.created_at <'2014-10-15'
group by 1,2

/*Analyzing Repeat Behavior*/
create temporary table session_with_repeats
select new_sessions.user_id,new_sessions.website_session_id as new_session_id,
website_sessions.website_session_id as repeat_session
from(select user_id,website_session_id
from website_sessions
where created_at < '2014-11-01' and created_at >= '2014-01-01' and is_repeat_session = 0) as new_sessions
 left join website_sessions
 on website_sessions.user_id = new_sessions.user_id
 and website_sessions.is_repeat_session =1
 and website_sessions.website_session_id > new_sessions.website_session_id
 and website_sessions.created_at < '2014-11-01'
 and website_sessions.created_at < '2014-01-01';
 
 select repeat_session,count(distinct user_id) as users
 from(select user_id,count(distinct new_session_id) as new_session,
 count(distinct repeat_session_id) as repeat_session
 from session_with_repeats
 group by 1
 order by 3) as user_level
 group by 1;


