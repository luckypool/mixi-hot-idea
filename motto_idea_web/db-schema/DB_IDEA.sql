DROP DATABASE if EXISTS mottoidea;
CREATE DATABASE mottoidea;
USE mottoidea;

DROP TABLE if EXISTS main_info;
CREATE TABLE main_info (
    idea_id INT unsigned NOT NULL,
    title VARCHAR(128) NOT NULL,
    status_id TINYINT unsigned NOT NULL,
    category_id TINYINT unsigned NOT NULL,
    positive_point INT unsigned NOT NULL,
    negative_point INT unsigned NOT NULL,
    inserted_at DATETIME NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT 0,
    PRIMARY KEY (idea_id),
    INDEX idx_inserted_at (inserted_at),
    INDEX idx_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE if EXISTS ranking_info;
CREATE TABLE ranking_info (
    idea_id INT unsigned NOT NULL,
    tendency INT unsigned NOT NULL DEFAULT 0,
    current_rank TINYINT unsigned NOT NULL,
    last_rank TINYINT unsigned NOT NULL,
    inserted_at DATETIME NOT NULL DEFAULT 0,
    updated_at DATETIME NOT NULL DEFAULT 0,
    PRIMARY KEY (idea_id),
    INDEX idx_inserted_at (inserted_at),
    INDEX idx_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

