create table orders(
order_id varchar(256) primary key,
customer_id varchar(256),
order_status varchar(100),
order_purchase_timestamp datetime,
order_approved_at datetime,
order_delivered_carrier_date datetime,
order_delivered_customer_date datetime,
order_estimated_delivery_date datetime,

foreign key(customer_id)
references customers(customer_id));

create table customers(
customer_id varchar(256) primary key,
customer_unique_id varchar(256),
zip_code int(10),
city varchar(100),
state varchar(10));

create table products(
product_id varchar(256) primary key,
product_category_name_english varchar(256),
product_name_length varchar(256),
product_description_length varchar(256),
product_photo_qty int(10),
product_weight_gm int,
product_length_cm int,
product_height_cm int,
product_width_cm int);

create table sellers(
seller_id varchar(256) primary key,
zip_code int,
seller_city varchar(100),
seller_state varchar(10));

create table order_items(
order_id varchar(256) primary key,
order_item_id int,
product_id varchar(256),
seller_id varchar(256),
shipping_limit_datetime datetime,
price decimal(10,2),
fright_value decimal(10,2),

foreign key(product_id)
references products(product_id),

foreign key (seller_id)
references sellers(seller_id));

create table order_payments(
order_id varchar(256) primary key,
payment_sequential int,
payment_type varchar(100),
payment_installments int,
payment_value decimal(10,2)
);

create table order_reviews(
review_id varchar(256) primary key,
order_id varchar(256),
review_score int(2), 
review_comment_title varchar(256),
review_comment_message text,
review_creation_date datetime,
review_answer_timestamp datetime,

foreign key(order_id)
references orders(order_id)
);

drop table order_payments;

select * from customers;
select * from orders;
select * from products;
select * from sellers;
select * from order_items;
select * from order_payments;
select * from order_reviews;