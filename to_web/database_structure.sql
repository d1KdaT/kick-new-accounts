CREATE TABLE `queue` (`account_id` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE `steamids` (`account_id` int(11) NOT NULL, `time_created` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE `queue` ADD PRIMARY KEY (`account_id`);
ALTER TABLE `steamids` ADD PRIMARY KEY (`account_id`);
