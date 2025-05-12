select * from album

-- 1) Who is the senior most employee based on job title?

SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

-- 2) Which countries have the most Invoices?

SELECT COUNT(*) total_counts, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY total_counts desc;

-- 3) What are top 3 values of total invoice?

SELECT total FROM invoice
ORDER BY total DESC
LIMIT 3;

-- 4) Which city has the best customers?
--	We would like to throw a promotional Music Festival in the city we made the most money.
--	Write a query that returns one city that has the highest sum of invoice totals. 
--	Return both the city name & sum of all invoice totals 

SELECT SUM(total) AS invoice_total, billing_city
FROM invoice 
GROUP BY billing_city
ORDER BY invoice_total DESC;

-- 5) Who is the best customer?
--	The customer who has spent the most money will be declared the best customer. 
--	Write a query that returns the person who has spent the most money

SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS Total
FROM customer c
JOIN invoice i 
ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER By Total DESC
LIMIT 1;


-- 6) Write query to return the email, first name, last name, & Genre of all Rock Music listeners.
--	Return your list ordered alphabetically by email starting with A

SELECT DISTINCT email,first_name, last_name 
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track t
	JOIN genre g ON t.genre_id = g.genre_id
	WHERE g.name LIKE 'Rock'
)
ORDER BY email;

-- 7) Let's invite the artists who have written the most rock music in our dataset.
--	Write a query that returns the Artist name and total track count of the top 10 rock bands

SELECT ar.artist_id, ar.name,COUNT(ar.artist_id) AS number_of_song
FROM track t
JOIN album a ON a.album_id = t.album_id
JOIN artist ar ON ar.artist_id = a.artist_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
GROUP By ar.artist_id
ORDER By number_of_song DESC
LIMIT 10;

-- 8) Return all the track names that have a song length longer than the average song length. 
--	Return the Name and Milliseconds for each track. 
--	Order by the song length with the longest songs listed first

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG (milliseconds) AS avg_track_length
	FROM track)
	ORDER BY milliseconds DESC;

-- 9) Find how much amount spent by each customer on artists? 
--	Write a query to return customer name, artist name and total spent

WITH best_selling_artist AS(
	SELECT ar.artist_id AS artist_id, ar.name AS artist_name,
	SUM(il.unit_price*il.quantity) AS total_sale
	FROM invoice_line il
	JOIN track t ON t.track_id = il.track_id
	JOIN album a ON a.album_id = t.album_id
	JOIN artist ar ON a.artist_id = a.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name,
SUM(il.unit_price*il.quantity) AS amount_spent
FROM Invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album a ON a.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = a.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


-- 10) We want to find out the most popular music Genre for each country. 
--	We determine the most popular genre as the genre with the highest amount of purchases. 
--	Write a query that returns each country along with the top Genre. 
--	For countries where the maximum number of purchases is shared return all Genres

WITH popular_genre AS
(
	SELECT COUNT(il.quantity) AS purchase, c.country, g.name, g.genre_id,
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS row_no
	FROM invoice_line il
	JOIN invoice i ON i.invoice_id = il.invoice_id
	JOIN customer c ON c.customer_id = i.customer_id 
	JOIN track t ON t.track_id = il.track_id
	JOIN genre g ON g.genre_id = t.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE row_no <= 1;


-- 11) Write a query that determines the customer that has spent the most on music for each country. 
--	Write a query that returns the country along with the top customer and how much they spent. 
--	For countries where the top amount spent is shared, provide all customers who spent this amount

WITH RECURSIVE
	customter_with_country AS (
	SELECT c.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
	FROM invoice i
	JOIN customer c ON c.customer_id = i.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cwc.billing_country, cwc.total_spending, cwc.first_name, cwc.last_name, cwc.customer_id
FROM customter_with_country cwc
JOIN country_max_spending cms ON cwc.billing_country = cms.billing_country
WHERE cwc.total_spending = cms.max_spending
ORDER BY 1;
	
-- Method 2 

WITH customter_with_country AS (
	SELECT c.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS row_no
	FROM invoice i
	JOIN customer c ON c.customer_id = i.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC, 5 DESC)
SELECT * FROM customter_with_country WHERE row_no <= 1;
