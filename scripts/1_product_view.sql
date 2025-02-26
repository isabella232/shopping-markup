# Copyright 2020 Google LLC..
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

-- Creates a latest snapshot view of products.
--
-- The Products_<Merchant Id> table has product data partitioned by date.
-- This view will get latest product data and create derived columns useful
-- for further processing of data.

CREATE OR REPLACE VIEW `{project_id}.{dataset}.product_view_{merchant_id}`
AS (
  WITH
    MultiChannelTable AS (
      SELECT DISTINCT
        _PARTITIONDATE,
        merchant_id,
        offer_id
      FROM
        `{project_id}.{dataset}.Products_{merchant_id}`
      GROUP BY
        _PARTITIONDATE,
        merchant_id,
        offer_id
      HAVING COUNT(DISTINCT(channel)) > 1
    ), LatestDate AS (
      SELECT
        MAX(_PARTITIONDATE) AS latest_date
      FROM
        `{project_id}.{dataset}.Products_{merchant_id}`
    )
  SELECT
    _PARTITIONDATE as data_date,
    LatestDate.latest_date,
    product_id,
    merchant_id,
    aggregator_id,
    offer_id,
    title,
    description,
    link,
    mobile_link,
    image_link,
    additional_image_links,
    content_language,
    target_country,
    channel,
    expiration_date,
    google_expiration_date,
    adult,
    age_group,
    availability,
    availability_date,
    brand,
    color,
    condition,
    custom_labels,
    gender,
    gtin,
    item_group_id,
    material,
    mpn,
    pattern,
    price,
    sale_price,
    google_product_category,
    google_product_category_path,
    product_type,
    additional_product_types,
    destinations,
    issues,
    CONCAT(CAST(Products.merchant_id AS STRING), '|', product_id) AS unique_product_id,
    IFNULL(SPLIT(product_type, '>')[SAFE_OFFSET(0)], 'N/A') AS product_type_l1,
    IFNULL(SPLIT(product_type, '>')[SAFE_OFFSET(1)], 'N/A') AS product_type_l2,
    IFNULL(SPLIT(product_type, '>')[SAFE_OFFSET(2)], 'N/A') AS product_type_l3,
    IFNULL(SPLIT(product_type, '>')[SAFE_OFFSET(3)], 'N/A') AS product_type_l4,
    IFNULL(SPLIT(product_type, '>')[SAFE_OFFSET(4)], 'N/A') AS product_type_l5,
    IFNULL(SPLIT(google_product_category_path, '>')[SAFE_OFFSET(0)], 'N/A') AS google_product_category_l1,
    IFNULL(SPLIT(google_product_category_path, '>')[SAFE_OFFSET(1)], 'N/A') AS google_product_category_l2,
    IFNULL(SPLIT(google_product_category_path, '>')[SAFE_OFFSET(2)], 'N/A') AS google_product_category_l3,
    IFNULL(SPLIT(google_product_category_path, '>')[SAFE_OFFSET(3)], 'N/A') AS google_product_category_l4,
    IFNULL(SPLIT(google_product_category_path, '>')[SAFE_OFFSET(4)], 'N/A') AS google_product_category_l5,
    IF(availability = 'in stock', 1, 0) AS in_stock,
    IF(MultiChannelTable.offer_id IS NULL, 'single_channel', 'multi_channel') AS channel_exclusivity
  FROM
    `{project_id}.{dataset}.Products_{merchant_id}` AS Products,
    LatestDate
    LEFT JOIN MultiChannelTable USING (_PARTITIONDATE, offer_id, merchant_id)
);
