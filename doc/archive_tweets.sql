DELIMITER //

CREATE PROCEDURE archive_tweets()
BEGIN
  -- copy data into archive tables and delete out-of-date data

  -- tweets
  INSERT INTO archive_tweets
    SELECT *
    FROM tweets
    WHERE created_at < DATE(DATE_SUB(NOW(), INTERVAL 7 DAY));
  DELETE
    FROM tweets
    WHERE created_at < DATE(DATE_SUB(NOW(), INTERVAL 7 DAY));

  -- link_tweets
  INSERT INTO archive_link_tweets
    SELECT *
    FROM link_tweets
    WHERE NOT EXISTS (
      SELECT tweets.twid
      FROM tweets
      WHERE tweets.twid = link_tweets.tweet_twid
      );
  DELETE
    FROM link_tweets
    WHERE NOT EXISTS (
      SELECT tweets.twid FROM tweets
      WHERE tweets.twid = link_tweets.tweet_twid
      );

  -- links
  INSERT INTO archive_links
    SELECT *
    FROM links
    WHERE NOT EXISTS (
      SELECT link_tweets.link_id
      FROM link_tweets
      WHERE link_tweets.link_id = links.id
      );
  DELETE
    FROM links
    WHERE NOT EXISTS (
      SELECT link_tweets.link_id
      FROM link_tweets
      WHERE link_tweets.link_id = links.id
      );

  -- users
  INSERT INTO archive_users
    SELECT *
    FROM users
    WHERE NOT EXISTS (
      SELECT tweets.user_id
      FROM tweets
      WHERE tweets.user_id = users.user_id
      );
  DELETE
    FROM users
    WHERE NOT EXISTS (
      SELECT tweets.user_id
      FROM tweets
      WHERE tweets.user_id = users.user_id
      );

  -- compact & reindex tables
  OPTIMIZE TABLE tweets;
  OPTIMIZE TABLE link_tweets;
  OPTIMIZE TABLE links;
  OPTIMIZE TABLE users;
END//
DELIMITER ;
