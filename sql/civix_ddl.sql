CREATE TABLE "dim_date_day" (
  "id" int4 NOT NULL,
  "value" int2 NOT NULL,
  "label" varchar(4) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "dim_date_month" (
  "id" int4 NOT NULL,
  "value" int2 NOT NULL,
  "label" varchar(16) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "dim_date_year" (
  "id" int4 NOT NULL,
  "value" int2 NOT NULL,
  "label" varchar(4) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "dim_election_type" (
  "id" int4 NOT NULL,
  "value" varchar(8) NOT NULL,
  "label" varchar(16) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "fact_vote" (
  "id" uuid NOT NULL,
  "voter_id" uuid NOT NULL,
  "van_id" varchar(32) NOT NULL,
  "ref_party_id" int2,
  "event_datestamp" date,
  "precinct" varchar(6),
  "ward" varchar(6),
  "dim_election_type_id" int2,
  "dim_date_month_id" int4,
  "dim_date_day_id" int4,
  "dim_date_year_id" int4,
  PRIMARY KEY ("id")
);
COMMENT ON COLUMN "fact_vote"."id" IS ' ';

CREATE TABLE "ref_party" (
  "id" int4 NOT NULL,
  "value" varchar(6) NOT NULL,
  "label" varchar(32),
  PRIMARY KEY ("id")
);

CREATE TABLE "voters" (
  "id" uuid NOT NULL,
  "van_id" varchar(32) NOT NULL,
  "first_name" varchar(32),
  "middle_name" varchar(32),
  "last_name" varchar(32),
  "name_suffix" varchar(10),
  "birth_year" int2,
  "voter_status" varchar(16),
  "ref_party_id" int2,
  "initial_reg_date" date,
  "last_reg_date" date,
  "house_number" int4,
  "direction_prefix" varchar(8),
  "street" varchar(32),
  "apartment" varchar(16),
  "city" varchar(32),
  "state_id" varchar(16),
  "zip" varchar(16),
  "reg_info_source" varchar(64),
  "ward" varchar(16),
  "precinct" varchar(16),
  "school_district" varchar(16),
  "congress_district" varchar(16),
  "house_district" varchar(16),
  "senate_district" varchar(16),
  "judicial_district" varchar(16),
  "county_council_district" varchar(16),
  PRIMARY KEY ("id")
);

ALTER TABLE "fact_vote" ADD CONSTRAINT "fk_fact_vote_dim_district_1" FOREIGN KEY ("dim_district_id") REFERENCES "dim_district" ("id");
ALTER TABLE "fact_vote" ADD CONSTRAINT "fk_fact_vote_dim_precinct_1" FOREIGN KEY ("dim_precinct_id") REFERENCES "dim_precinct" ("id");
ALTER TABLE "fact_vote" ADD CONSTRAINT "fk_fact_vote_dim_ward_1" FOREIGN KEY ("dim_ward_id") REFERENCES "dim_ward" ("id");
ALTER TABLE "fact_vote" ADD CONSTRAINT "fk_fact_vote_dim_election_type_1" FOREIGN KEY ("dim_election_type_id") REFERENCES "dim_election_type" ("id");
ALTER TABLE "fact_vote" ADD CONSTRAINT "fk_fact_vote_dim_date_month_1" FOREIGN KEY ("dim_date_month_id") REFERENCES "dim_date_month" ("id");
ALTER TABLE "fact_vote" ADD CONSTRAINT "fk_fact_vote_dim_date_day_1" FOREIGN KEY ("dim_date_day_id") REFERENCES "dim_date_day" ("id");
ALTER TABLE "fact_vote" ADD CONSTRAINT "fk_fact_vote_dim_date_year_1" FOREIGN KEY ("dim_date_year_id") REFERENCES "dim_date_year" ("id");
ALTER TABLE "fact_vote" ADD CONSTRAINT "fk_fact_vote_voters_1" FOREIGN KEY ("voter_id") REFERENCES "voters" ("id");

