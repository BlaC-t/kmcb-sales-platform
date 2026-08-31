-- Sales Platform 产品目录首批初始化
-- 目标：192.168.9.121 / kj_sale_platform
-- 来源：用户提供的三份产品 Excel；直线筛文件中的分级机 Sheet 不纳入本批次。
-- 幂等：来源版本按 file_sha256、产品按 source_id+sheet+row、问题按 product_id+issue_code 更新。

SET NAMES utf8mb4;
CREATE DATABASE IF NOT EXISTS kj_sale_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE kj_sale_platform;

CREATE TABLE IF NOT EXISTS sp_product_source_file (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  file_name VARCHAR(255) NOT NULL,
  file_sha256 CHAR(64) NOT NULL,
  source_type VARCHAR(32) NOT NULL DEFAULT 'XLSX',
  record_count INT UNSIGNED NOT NULL DEFAULT 0,
  review_issue_count INT UNSIGNED NOT NULL DEFAULT 0,
  import_status VARCHAR(32) NOT NULL DEFAULT 'PARSED',
  imported_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_sp_source_file_name (file_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS sp_equipment_product (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  source_id BIGINT UNSIGNED NOT NULL,
  product_kind VARCHAR(40) NOT NULL,
  family VARCHAR(160) NOT NULL,
  series_name VARCHAR(80) NULL,
  product_name VARCHAR(120) NULL,
  model VARCHAR(120) NULL,
  raw_model VARCHAR(120) NULL,
  drawing_no VARCHAR(160) NULL,
  weight_kg VARCHAR(80) NULL,
  quote_weight_t VARCHAR(80) NULL,
  dimensions VARCHAR(160) NULL,
  main_spec VARCHAR(160) NULL,
  screen_area_m2 VARCHAR(80) NULL,
  deck_count VARCHAR(40) NULL,
  inclination VARCHAR(80) NULL,
  amplitude VARCHAR(80) NULL,
  frequency VARCHAR(80) NULL,
  capacity_tph VARCHAR(80) NULL,
  feed_size_mm VARCHAR(80) NULL,
  power_kw VARCHAR(80) NULL,
  motor_model VARCHAR(255) NULL,
  standard_supply TEXT NULL,
  options_text TEXT NULL,
  transport_text TEXT NULL,
  remarks TEXT NULL,
  quality_status VARCHAR(32) NOT NULL DEFAULT 'READY',
  issue_count INT UNSIGNED NOT NULL DEFAULT 0,
  source_sheet VARCHAR(160) NOT NULL,
  source_row INT UNSIGNED NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_sp_product_source_row (source_id, source_sheet, source_row),
  KEY idx_sp_product_kind_model (product_kind, model),
  KEY idx_sp_product_quality (quality_status),
  CONSTRAINT fk_sp_product_source FOREIGN KEY (source_id) REFERENCES sp_product_source_file (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS sp_equipment_quality_issue (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  issue_code VARCHAR(64) NOT NULL,
  issue_message VARCHAR(255) NOT NULL,
  review_status VARCHAR(32) NOT NULL DEFAULT 'OPEN',
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_sp_quality_product_issue (product_id, issue_code),
  KEY idx_sp_quality_status (review_status),
  CONSTRAINT fk_sp_quality_product FOREIGN KEY (product_id) REFERENCES sp_equipment_product (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

START TRANSACTION;

INSERT INTO sp_product_source_file (file_name, file_sha256, record_count, review_issue_count, import_status)
VALUES ('圆振动筛产品参数表-260626.xlsx', '8f1e8ecba6be0aaca95d6b1874cb2a2b6a6e116e85cd3b2e7fbda444e7c6ca47', 56, 39, 'PARSED')
ON DUPLICATE KEY UPDATE file_sha256=VALUES(file_sha256), record_count=VALUES(record_count), review_issue_count=VALUES(review_issue_count), import_status=VALUES(import_status), imported_at=CURRENT_TIMESTAMP(3);
SET @src_circular = (SELECT id FROM sp_product_source_file WHERE file_sha256='8f1e8ecba6be0aaca95d6b1874cb2a2b6a6e116e85cd3b2e7fbda444e7c6ca47');

INSERT INTO sp_product_source_file (file_name, file_sha256, record_count, review_issue_count, import_status)
VALUES ('洗矿机产品在销售版本明细表(2026.04洗矿机更新).xlsx', 'ddf5c981025f9678a397594b4546164a5f8470521b583b4d16a24bbdb31ce7d7', 13, 0, 'PARSED')
ON DUPLICATE KEY UPDATE file_sha256=VALUES(file_sha256), record_count=VALUES(record_count), review_issue_count=VALUES(review_issue_count), import_status=VALUES(import_status), imported_at=CURRENT_TIMESTAMP(3);
SET @src_washer = (SELECT id FROM sp_product_source_file WHERE file_sha256='ddf5c981025f9678a397594b4546164a5f8470521b583b4d16a24bbdb31ce7d7');

INSERT INTO sp_product_source_file (file_name, file_sha256, record_count, review_issue_count, import_status)
VALUES ('直线筛产品在销售版本明细表-2026.4.20.xlsx', '8e3de379b54d8fd1f5d8d541cb3610eca63da4067c2a722624cf85ccf4633033', 41, 28, 'PARSED')
ON DUPLICATE KEY UPDATE file_sha256=VALUES(file_sha256), record_count=VALUES(record_count), review_issue_count=VALUES(review_issue_count), import_status=VALUES(import_status), imported_at=CURRENT_TIMESTAMP(3);
SET @src_linear = (SELECT id FROM sp_product_source_file WHERE file_sha256='8e3de379b54d8fd1f5d8d541cb3610eca63da4067c2a722624cf85ccf4633033');

INSERT INTO sp_equipment_product (source_id, product_kind, family, series_name, product_name, model, raw_model, drawing_no, weight_kg, quote_weight_t, dimensions, main_spec, screen_area_m2, deck_count, inclination, amplitude, frequency, capacity_tph, feed_size_mm, power_kw, motor_model, standard_supply, options_text, transport_text, remarks, quality_status, issue_count, source_sheet, source_row) VALUES
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '09系列', '自定中心振动筛', 'SZZ-918', 'SZZ-918', 'SF45B.0', '550', '', '1952*1400*1640', '900*1800', '1.62', '1', '10°～23°', '6～10', '900', '15～90', '200', '2.2', 'YE3-100L1-4-2.2kW-IP55', '筛体
振动器
隔振弹簧
支座
电动机', '喷水管、进料槽、出料槽、筛下料仓等', '', '传动部可根据需要安装在任何一侧，标准配置为右侧；筛隙订货时确定', 'READY', '0', 'Sheet1', '3'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '09系列', '自定中心振动筛', '2SZZ-918', '2SZZ-918', '', '', '', '', '', '', '2', '', '', '', '', '', '2.2', 'YE3-100L1-4-2.2kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '4'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '09系列', '自定中心振动筛', 'SZZ-927', 'SZZ-927', 'SF48B.0', '650', '', '2830*1725*1630', '900*2700', '2.43', '1', '10°～23°', '6～10', '900', '22～135', '', '2.2（给矿型3）', 'YE3-100L1-4-2.2kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '5'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '09系列', '自定中心振动筛', '2SZZ-927', '2SZZ-927', 'SF51B.0', '880', '', '3050*1960*1630', '', '', '2', '', '', '', '', '', '3', 'YE3-100L2-4-3kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '6'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '12系列', '自定中心振动筛', 'SZZ-1225', 'SZZ-1225', 'SF06C.0', '1630', '', '2760*2280*2020', '1250*2500', '3.13', '1', '10°～23°', '6～10', '900', '25～160', '', '4', 'YE3-112M-4-4kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '7'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '12系列', '自定中心振动筛', '2SZZ-1225', '2SZZ-1225', '', '', '', '', '', '', '2', '', '', '', '', '', '4', 'YE3-112M-4-4kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '8'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '12系列', '自定中心振动筛', '3SZZ-1225', '3SZZ-1225', '', '', '', '', '', '', '3', '', '', '', '', '', '5.5', 'YE3-132S-4-5.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '9'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '12系列', '自定中心振动筛', 'SZZ-1232', 'SZZ-1232', 'SF43C.0C', '1650', '', '3800*2270*2260', '1250*3000', '4', '1', '10°～23°', '6～10', '900', '32～200', '', '5.5(给矿型7.5)', 'YE3-132S-4-5.5kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '10'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '12系列', '自定中心振动筛', '2SZZ-1232', '2SZZ-1232', 'SF54E.0A', '2390', '', '3680*2320*2450', '', '', '2', '', '', '', '', '', '7.5', 'YE3-132M-4-7.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '11'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '12系列', '自定中心振动筛', '3SZZ-1232', '3SZZ-1232', '', '', '', '', '', '', '3', '', '', '', '', '', '7.5', 'YE3-132M-4-7.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '12'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '15系列', '自定中心振动筛', '2SZZ-1548', '2SZZ-1548', 'SF53C.0(C1125)', '5120', '', '5040*3070*2730', '1500*4800', '7.2', '2', '10°～23°', '6～10', '970', '60～400', '', '15', 'YE3-180L-6-15kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '13'),
(@src_circular, 'circular-screen', 'SZZ型自定中心振动筛', '15系列', '自定中心振动筛', '2SZZ-1548', '', 'SF53D.0', '5100', '', '5290*2680*3200', '', '', '2', '', '', '820', '', '', '15', 'YE3-160L-4-15kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '14'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', 'YK-1530', 'YK-1530', 'SF0902.0', '2130', '', '3830*2260*1900', '1500*3250', '4.88', '1', '10°～23°', '6～10', '1000', '50～300', '250', '2×4', 'SVE 6500/1N-FD-90EAA', '筛体
振动器
隔振弹簧
支座
电动机', '喷水管、进料槽、出料槽、筛下料仓等', '', '传动部可根据需要安装在任何一侧，标准配置为右侧；筛隙订货时确定', 'READY', '0', 'Sheet1', '19'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', 'YK-1530', 'YK-1530', 'SF0901.0', '2260', '', '3830*2960*1880', '', '', '', '', '', '970', '', '', '7.5', 'YE3-160M-6-7.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '20'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', 'YKR-1530', 'YKR-1530', 'SF09C.0(C1761)', '2230', '', '4030*3010*1350', '', '', '', '', '', '', '', '', '7.5', 'YE3-160M-6-7.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '21'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', 'YA-1536', 'YA-1536', 'SF10901.0A', '3380', '', '4320*2580*2640', '1500*3600', '5.4', '1', '', '', '850', '', '', '11', 'YE3-160M-4-11kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '22'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', 'YA-1536', '', 'SF81.0', '3010', '', '3780*2540*2320', '', '', '', '', '', '', '', '', '7.5', 'YE3-132M-4-7.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '23'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', '2YA-1536', '2YA-1536', 'SF131.0', '5180', '', '4230*3150*3050', '', '', '2', '', '', '830', '', '', '15', 'YE3-160L-4-15kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '24'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', '3YA-1536', '3YA-1536', '', '', '', '', '', '', '3', '', '', '', '', '', '18.5', 'YE3-180M-4-18.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '25'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', 'YA-1548', 'YA-1548', 'SF11201.0', '4870', '', '5440*2680*3100', '1500*4800', '7.2', '1', '10°～23°', '6～10', '850', '60～400', '', '15', 'YE3-160L-4-15kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '26'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', '2YA-1548', '2YA-1548', 'SF106.0A', '4970', '', '5340*3170*3520', '', '', '2', '', '', '', '', '', '18.5', 'YE3-180M-4-18.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '27'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '15系列', '圆振动筛', '3YA-1548', '3YA-1548', '', '', '', '', '', '', '3', '', '', '', '', '', '22', 'YE3-180L-4-22kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '28'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '18系列', '圆振动筛', 'YA-1836', 'YA-1836', 'SF101.0', '4650', '', '4300*3080*2560', '1800*3600', '6.48', '1', '10°～23°', '6～10', '850', '60～400', '', '15', 'YE3-180L-6-15kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '29'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '18系列', '圆振动筛', '2YA-1836', '2YA-1836', 'SF13B.0(C0903)', '5850', '', '3750*3520*2250', '', '', '2', '', '', '', '', '', '18.5', 'YE3-180M-4-18.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '30'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '18系列', '圆振动筛', '3YK-1836', '3YK-1836', 'SF13601.0', '6480', '', '4120*3515*3390', '', '', '3', '', '', '', '', '', '18.5', 'YE3-180M-4-18.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '31')
ON DUPLICATE KEY UPDATE product_kind=VALUES(product_kind), family=VALUES(family), series_name=VALUES(series_name), product_name=VALUES(product_name), model=VALUES(model), raw_model=VALUES(raw_model), drawing_no=VALUES(drawing_no), weight_kg=VALUES(weight_kg), quote_weight_t=VALUES(quote_weight_t), dimensions=VALUES(dimensions), main_spec=VALUES(main_spec), screen_area_m2=VALUES(screen_area_m2), deck_count=VALUES(deck_count), inclination=VALUES(inclination), amplitude=VALUES(amplitude), frequency=VALUES(frequency), capacity_tph=VALUES(capacity_tph), feed_size_mm=VALUES(feed_size_mm), power_kw=VALUES(power_kw), motor_model=VALUES(motor_model), standard_supply=VALUES(standard_supply), options_text=VALUES(options_text), transport_text=VALUES(transport_text), remarks=VALUES(remarks), quality_status=VALUES(quality_status), issue_count=VALUES(issue_count);

INSERT INTO sp_equipment_product (source_id, product_kind, family, series_name, product_name, model, raw_model, drawing_no, weight_kg, quote_weight_t, dimensions, main_spec, screen_area_m2, deck_count, inclination, amplitude, frequency, capacity_tph, feed_size_mm, power_kw, motor_model, standard_supply, options_text, transport_text, remarks, quality_status, issue_count, source_sheet, source_row) VALUES
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '18系列', '圆振动筛', 'YA-1848', 'YA-1848', 'SF110.0A', '5330', '', '5400*3050*3100', '1800*4800', '8.64', '1', '10°～23°', '6～10', '850', '80～480', '', '18.5', 'YE3-180M-4-18.5kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '32'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '18系列', '圆振动筛', '2YA-1848', '2YA-1848', '', '', '', '', '', '', '2', '', '', '', '', '', '22', 'YE3-180L-4-22kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '33'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '18系列', '圆振动筛', '3YA-1848', '3YA-1848', '', '', '', '', '', '', '3', '', '', '', '', '', '30', '', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '34'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '18系列', '圆振动筛', '2YA-1860', '2YA-1860', 'SF12801.0', '8000', '', '6580*3480*4020', '1800*6000', '10.8', '2', '10°～23°', '6～10', '850', '100～550', '', '22', 'YE3-180L-4-22kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '35'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '21系列', '圆振动筛', '2YK-2142', '2YK-2142', 'SF13301.0', '7600', '', '4760*3660*3020', '2100*4200', '8.82', '2', '10°～23°', '6～10', '830', '100～550', '', '22', 'YE3-180L-4-22kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '36'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '21系列', '圆振动筛', 'YA-2148', 'YA-2148', 'SF100.0(C0675)', '5890', '', '5440*3350*2780', '2100*4800', '10.08', '1', '10°～23°', '6～10', '830', '100～600', '', '22', 'YE3-180L-4-22kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '37'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '21系列', '圆振动筛', '2YA-2148', '2YA-2148', 'SF78A.0', '7350', '', '5370*3760*3400', '', '', '2', '', '', '', '', '', '22', 'YE3-180L-4-22kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '38'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '21系列', '圆振动筛', 'YA-2160', 'YA-2160', 'SF111B.0(C509)', '7100', '', '6550*3710*3620', '2100*6000', '12.6', '1', '10°～23°', '6～10', '970', '120～700', '', '22', 'YE3-200L2-6-22kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '39'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '21系列', '圆振动筛', '2YK-2160', '2YK-2160', 'SF107B.0', '8150', '', '6500*3810*3980', '', '', '2', '', '', '830', '', '', '30', 'YE3-200L-4-30kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '40'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '21系列', '圆振动筛', '3YK-2160', '3YK-2160', 'SF124A.0', '10150', '', '6500*3810*4070', '', '', '3', '', '', '830', '', '', '30', 'YE3-200L-4-30kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', 'Sheet1', '41'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '21系列', '圆振动筛', '2YK-2178', '2YK-2178', 'SF132.0', '11350', '', '8090*3790*4530', '2100*7800', '16.38', '2', '10°～23°', '6～10', '830', '150～910', '', '2×18.5', 'YE3-180M-4-18.5kW-IP55', '', '', '', '', 'READY', '0', 'Sheet1', '42'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', 'YK-2460', 'YK-2460', 'SF11601.0', '6950', '', '6680*4440*3170', '2400*6000', '14.4', '1', '10°～23°', '6～10', '830', '135～800', '', '22', 'YE3-180L-4-22kW-IP55', '', '', '', '稀油激振器，减速传动', 'READY', '0', 'Sheet1', '43'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', 'YK-2460', '', 'SF116A.0A(C1019)', '5980', '', '6620*4070*2480', '', '', '', '', '', '850', '', '', '22', 'YE3-180L-4-22kW-IP55', '', '', '', '干油激振器，减速传动', 'NEEDS_REVIEW', '1', 'Sheet1', '44'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', 'YK-2460', '', 'SF116A.0(C0421)', '5550', '', '6620*4000*2480', '', '', '', '', '', '970', '', '', '22', 'YE3-200L2-6-22kW-IP55', '', '', '', '干油激振器，电机直联', 'NEEDS_REVIEW', '1', 'Sheet1', '45'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', 'YK-2460', '', 'SF116B.0(C1302)', '7830', '', '6510*4070*3600', '', '', '', '', '', '850', '', '', '30', 'YE3-200L-4-30kW-IP55', '', '', '', '干油激振器，减速传动', 'NEEDS_REVIEW', '1', 'Sheet1', '46'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '2YK-2460', '2YK-2460', 'SF11501.0', '9420', '', '6570*3350*4300', '', '', '2', '', '', '970', '', '', '2×11', 'SVE18000-1N-105FD-B', '', '', '', '侧板振动电机，自同步', 'NEEDS_REVIEW', '1', 'Sheet1', '47'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '2YK-2460', '', 'SF11502.0(C2238)', '9100', '', '6580*4160*4430', '', '', '', '', '', '830', '', '', '37', 'YE3-225S-4-37kW-IP55', '', '', '', '干油激振器，减速传动', 'NEEDS_REVIEW', '1', 'Sheet1', '48'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '2YK-2460', '', 'SF115A.0(C1953)', '12600', '', '6550*4160*4220', '', '', '', '', '', '830', '', '', '37', 'YE3-225S-4-37kW-IP55', '', '', '', '干油激振器，减速传动', 'NEEDS_REVIEW', '1', 'Sheet1', '49'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', 'YK-2472', 'YK-2472', 'SF102A.0', '8210', '', '7570*4270*4370', '2400*7200', '17.28', '1', '10°～23°', '6～10', '980', '160～960', '', '37', 'YE3-250M-6-37kW-IP55', '', '', '', '干油激振器，电机直联', 'READY', '0', 'Sheet1', '50'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', 'YK-2472', '', 'SF102B.0', '8530', '', '7590*4160*4380', '', '', '', '', '', '825', '', '', '37', 'YE3-225S-4-37kW-IP55', '', '', '', '干油激振器，减速传动', 'NEEDS_REVIEW', '1', 'Sheet1', '51'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', 'YK-3060', 'YK-3060', '', '', '', '', '3000*6000', '18', '1', '10°～23°', '6～10', '', '167～1000', '', '22', '', '', '', '', '', 'NEEDS_REVIEW', '2', 'Sheet1', '52'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '2YK-3060', '2YK-3060', '', '', '', '', '', '', '2', '', '', '', '', '', '30', '', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '53'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '3YK-3060', '3YK-3060', '', '', '', '', '', '', '3', '', '', '', '', '', '45', '', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '54'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', 'YK-3072', 'YK-3072', 'SF118A.0(C1501)', '10760', '', '7940*4820*4310', '3000*7200', '21.6', '1', '10°～23°', '6～10', '830', '200～1200', '', '30', 'YE3-200L-4-30kW-IP55', '', '', '', '干油激振器，减速传动', 'READY', '0', 'Sheet1', '55'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', 'YK-3072', '', 'SF11801.0', '10000', '', '7910*4880*3620', '', '', '', '', '', '830', '', '', '22', 'YE3-180L-4-22kW-IP55', '', '', '', '稀油激振器，减速传动', 'NEEDS_REVIEW', '1', 'Sheet1', '56')
ON DUPLICATE KEY UPDATE product_kind=VALUES(product_kind), family=VALUES(family), series_name=VALUES(series_name), product_name=VALUES(product_name), model=VALUES(model), raw_model=VALUES(raw_model), drawing_no=VALUES(drawing_no), weight_kg=VALUES(weight_kg), quote_weight_t=VALUES(quote_weight_t), dimensions=VALUES(dimensions), main_spec=VALUES(main_spec), screen_area_m2=VALUES(screen_area_m2), deck_count=VALUES(deck_count), inclination=VALUES(inclination), amplitude=VALUES(amplitude), frequency=VALUES(frequency), capacity_tph=VALUES(capacity_tph), feed_size_mm=VALUES(feed_size_mm), power_kw=VALUES(power_kw), motor_model=VALUES(motor_model), standard_supply=VALUES(standard_supply), options_text=VALUES(options_text), transport_text=VALUES(transport_text), remarks=VALUES(remarks), quality_status=VALUES(quality_status), issue_count=VALUES(issue_count);

INSERT INTO sp_equipment_product (source_id, product_kind, family, series_name, product_name, model, raw_model, drawing_no, weight_kg, quote_weight_t, dimensions, main_spec, screen_area_m2, deck_count, inclination, amplitude, frequency, capacity_tph, feed_size_mm, power_kw, motor_model, standard_supply, options_text, transport_text, remarks, quality_status, issue_count, source_sheet, source_row) VALUES
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '2YK-3072', '2YK-3072', 'SF10401.0', '14380', '', '7730*5070*4740', '', '', '2', '', '', '830', '', '', '37', 'YE3-225S-4-37kW-IP55', '', '', '', '稀油激振器，减速传动', 'NEEDS_REVIEW', '1', 'Sheet1', '57'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '2YK-3072', '', 'SF104C.0', '10800', '', '7660*4860*4410', '', '', '', '', '', '980', '', '', '37', 'YE3-250M-6-37kW-IP55', '', '', '', '干油激振器，电机直联', 'NEEDS_REVIEW', '1', 'Sheet1', '58'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '2YK-3072', '', 'SF104D.0', '13300', '', '7670*4720*4450', '', '', '', '', '', '830', '', '', '37', 'YE3-225S-4-37kW-IP55', '', '', '', '干油激振器，减速传动', 'NEEDS_REVIEW', '1', 'Sheet1', '59'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '3YK-3072', '3YK-3072', '', '', '', '', '3000*7200', '21.6', '3', '', '', '', '', '', '', '', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '60'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '2YK-3685', '2YK-3685', '', '', '', '', '3600*8500', '30.6', '2', '10°～23°', '6～10', '', '', '', '', '', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '61'),
(@src_circular, 'circular-screen', 'YK（A）型圆振动筛', '24系列', '圆振动筛', '3YK-3685', '3YK-3685', '', '', '', '', '', '', '3', '', '', '', '', '', '', '', '', '', '', '', 'NEEDS_REVIEW', '3', 'Sheet1', '62'),
(@src_washer, 'washer', '槽式洗矿机', '槽式', '双螺旋槽式洗矿机', 'XK-1156', 'XK-1156', 'XK01A.0A', '4572', '4.6', '6760*1520*2340', '1100*5600', '', '', '10～14', '', '', '20～40', '≤50', '15', 'YE3-160L-4', '排矿阀、槽体、螺旋叶片轴、电动机、减速机、V带、皮带罩、安装用支座、防护网、喷水管', '可选配YE3-160M-4电动机,功率11kW', '整机运输', '根据定货要求，按转速带轮配比表选择大小皮带轮;喷水管在安装现场根据使用情况配焊', 'READY', '0', '洗矿机(202604核对）', '4'),
(@src_washer, 'washer', '槽式洗矿机', '槽式', '双螺旋槽式洗矿机', 'XK-1572', 'XK-1572', 'XK09.0D', '8050', '8.1', '8380*1931*1740', '1500*7200', '', '', '7～11', '', '', '40～80', '≤50', '22', 'YE3-180L-4', '排矿阀、槽体、螺旋叶片轴、电动机、减速机、V带、皮带罩、安装用支座、安全防护网、喷水管', '可选配YE3-200L-4电动机，功率30kW或YE3-180M-4电动机，功率18.5kW', '整机运输', '根据定货要求，按转速带轮配比表选择大小皮带轮；喷水管用户根据实际情况确定位置后安装', 'READY', '0', '洗矿机(202604核对）', '5'),
(@src_washer, 'washer', '槽式洗矿机', '槽式', '双螺旋槽式洗矿机', 'XK-2080', 'XK-2080', 'XK10C.0C
XK1001～2.0', '15170', '17.9', '10638*2120*1700', '1950*8000', '', '', '6～10', '', '', '50～120', '≤50', '37', 'YE3-225S-4', '排矿阀、槽体、螺旋叶片轴、电动机、减速机、V带、安装用支座、安全防护网、喷水管', '可选配电机减速机，功率37kW', '整机运输', '根据定货要求，按转速带轮配比表选择大小皮带轮；喷水管用户根据实际情况确定位置后配焊', 'READY', '0', '洗矿机(202604核对）', '6'),
(@src_washer, 'washer', '槽式洗矿机', '槽式', '双螺旋槽式洗矿机', 'XK-2284', 'XK-2284', 'XK0303.0', '18200', '19.5', '11787*2450*2185', '2200*8400', '', '', '8～12', '', '', '40～120', '≤50', '55', '减速电机
ER177-Y55-4P-68', '排矿阀、槽体、螺旋叶片轴、电机减速机、安装用支座、安全防护网、喷水管', '', '整机运输', '喷水管、防护网在安装现场，根据使用情况确定位置后配焊', 'READY', '0', '洗矿机(202604核对）', '7'),
(@src_washer, 'washer', '槽式洗矿机', '槽式', '双螺旋槽式洗矿机', 'XK-2496', 'XK-2496', 'XK12A.0
XK1801～4.0', '21374', '22', '12581*2584*1970', '2400*9650', '', '', '6～9', '', '', '80～160', '≤50', '90', 'YE3-280M-4', '排矿阀、槽体、螺旋叶片轴、电动机、减速机、V带、安装用支座、安全防护网、喷水管', '', '整机运输', '喷水管、防护网在安装现场，根据使用情况确定位置后配焊', 'READY', '0', '洗矿机(202604核对）', '8'),
(@src_washer, 'washer', '槽式洗矿机', '槽式', '单螺旋槽式洗矿机', 'XK-1296D', 'XK-1296D', 'XK2101.0', '14058', '14.5', '12407*1884*1920', '1700*9650', '', '', '6～9', '', '', '80～150', '≤200', '55', 'YE3-250M-4', '排矿阀、槽体、螺旋叶片轴、电动机、减速机、V带、安装用支座、安全防护网、喷水管', '可选配电机减速机，功率55kW', '整机运输', '喷水管、防护网在安装现场，根据使用情况确定位置后配焊', 'READY', '0', '洗矿机(202604核对）', '9'),
(@src_washer, 'washer', '圆筒洗矿机', '圆筒', '圆筒洗矿机', 'TX-1766', 'TX-1766', 'XK13.0/Ⅱ', '32652', '32.7', '8800*3000*3300', 'φ1700*6600', '', '', '', '', '16-13', '25-150', '小于200', '45', '减速电机
GR137-Y45-4P', '喷射润滑系统、控制柜、筒体、筒筛、喷水管、齿轮罩、传动部件、测温装置、地脚螺栓', '盘车装置、进料槽、半移动钢架、出料罩', '①标准配置：筒体(含衬板)、对开齿轮、筒筛祼装1包，其它部分散装或集中打1包或装1箱；
②半移动式：筒体(含部分衬板)、筒筛、底架、托轮部、传动部祼装1包，剩余衬板打包和其它部分散装或集中打1包或装1箱。', '定货时注明旋向，面向出料端，筒体顺时针为右旋，为标配，可选左旋', 'READY', '0', '洗矿机(202604核对）', '12'),
(@src_washer, 'washer', '圆筒洗矿机', '圆筒', '圆筒洗矿机', 'TX-2260', 'TX-2260', 'XK17.0', '37200', '37.2', '6234*3728*3582', 'φ2200*6000', '', '', '', '', '5-13.5
变频调速', '30-150', '小于300', '55', '减速电机
R13-10.79-YVP55-4P', '筒体、传动部件、筒筛、喷水管、齿轮罩、控制柜，测温装置、地脚螺栓', '喷射润滑系统、盘车装置、进料槽、半移动钢架、出料罩', '①标准配置：筒体(含衬板)、对开齿轮、筒筛祼装1包，其它部分散装或集中打1包或装1箱；
②半移动式：筒体(含部分衬板)、筒筛、底架、托轮部、传动部祼装1包，剩余衬板打包和其它部分散装或集中打1包或装1箱。', '定货时注明旋向，面向出料端，筒体顺时针为右旋，为标配，可选左旋', 'READY', '0', '洗矿机(202604核对）', '13'),
(@src_washer, 'washer', '圆筒洗矿机', '圆筒', '圆筒洗矿机', 'TX-2296', 'TX-2296', 'XK2401.0', '48620', '50.15', '12839*3725*3762', 'φ2200*9600', '', '', '', '', '12', '100-200', '小于300', '75', '减速电机
ER147-Y75-4P', '筒体、传动部件、齿轮罩、筒筛、喷水管、齿轮罩、控制柜、测温装置、地脚螺栓', '喷射润滑系统、盘车装置、进料槽、半移动钢架', '①标准配置：筒体(含部分衬板)祼装1包，筒筛祼装1包，对开齿轮1包，剩余衬板打包其它部分散装或集中打1包或装1箱；
②半移动式：筒体(含部分衬板)祼装1包，筒筛、底架、托轮、传动部1包，对开齿轮1包，剩余衬板打包和其它部分散装或集中打1包或装1箱。', '定货时注明旋向，面向出料端，筒体顺时针为右旋，为标配，可选左旋', 'READY', '0', '洗矿机(202604核对）', '14'),
(@src_washer, 'washer', '圆筒洗矿机', '圆筒', '圆筒洗矿机', 'TX-2462', 'TX-2462', 'XK14.0Ⅰ', '37500', '37.5', '6200*5780*4380', 'φ2400*6200', '', '', '', '', '7-11', '100-200', '小于300', '90', '南京变频调速电机
YTP280M/4/90kW', '喷射润滑系统、筒体、传动部件、齿轮罩、筒筛、喷水管、齿轮罩、控制柜、测温装置、地脚螺栓', '盘车装置、进料槽、半移动钢架、出料罩', '①标准配置：筒体(含部分衬板)、筒筛祼装1包，对开齿轮1包，剩余衬板打包其它部分散装或集中打1包或装1箱；
②半移动式：筒体(含部分衬板)祼装1包，筒筛、底架、托轮、传动部1包，对开齿轮1包，剩余衬板打包和其它部分散装或集中打1包或装1箱。', '定货时注明旋向，面向出料端，筒体顺时针为右旋，为标配，可选左旋', 'READY', '0', '洗矿机(202604核对）', '15'),
(@src_washer, 'washer', '圆筒洗矿机', '圆筒', '圆筒洗矿机', 'TX-2472', 'TX-2472', 'XK15.0', '40500', '40.5', '10500*4000*4300', 'φ2400*7200', '', '', '', '', '7-13', '100-300', '≦300', '55', '减速电机
GR167-Y55-4P', '筒体、传动部件、齿轮罩、筒筛、喷水管、齿轮罩、控制柜、测温装置、地脚螺栓', '喷射润滑系统、盘车装置、进料槽、半移动钢架、出料罩', '①标准配置：筒体(含部分衬板)、筒筛祼装1包，对开齿轮1包，剩余衬板打包其它部分散装或集中打1包或装1箱；
②半移动式：筒体(含部分衬板)祼装1包，筒筛、底架、托轮、传动部1包，对开齿轮1包，剩余衬板打包和其它部分散装或集中打1包或装1箱。', '定货时注明旋向，面向出料端，筒体顺时针为右旋，为标配，可选左旋', 'READY', '0', '洗矿机(202604核对）', '16'),
(@src_washer, 'washer', '圆筒洗矿机', '圆筒', '圆筒洗矿机', 'TX-2496', 'TX-2496', 'XK19', '55806', '56', '12355*3910*4275', 'φ2400*9600', '', '', '', '', '11', '100-200', '≦300', '90', '减速电机
ER147-Y90-4P', '筒体、传动部件、齿轮罩、筒筛、喷水管、齿轮罩、控制柜、测温装置、地脚螺栓', '喷射润滑系统、盘车装置、进料槽、半移动钢架、出料罩', '①标准配置：筒体(含部分衬板)祼装1包，筒筛祼装1包，对开齿轮1包，剩余衬板打包其它部分散装或集中打1包或装1箱；
②半移动式：筒体(含部分衬板)祼装1包，筒筛、底架、托轮、传动部1包，对开齿轮1包，剩余衬板打包和其它部分散装或集中打1包或装1箱。', '定货时注明旋向，面向出料端，筒体顺时针为右旋，为标配，可选左旋', 'READY', '0', '洗矿机(202604核对）', '17'),
(@src_washer, 'washer', '圆筒洗矿机', '圆筒', '圆筒洗矿机', 'TX-30100', 'TX-30100', 'XK20', '78216', '79', '13240*4462*4790', 'φ3000*10000', '', '', '', '', '10', '100-400', '≦300', '110', '减速电机
ER167-Y110-4P', '筒体、传动部件、齿轮罩、筒筛、喷水管、齿轮罩、控制柜、测温装置、地脚螺栓', '喷射润滑系统、盘车装置、进料槽、半移动钢架、出料罩', '①标准配置：筒体(含部分衬板)祼装1包，筒筛祼装1包，对开齿轮1包，剩余衬板打包其它部分散装或集中打1包或装1箱；
②半移动式：筒体(含部分衬板)祼装1包，筒筛、底架、托轮、传动部1包，对开齿轮1包，剩余衬板打包和其它部分散装或集中打1包或装1箱。', '定货时注明旋向，面向出料端，筒体顺时针为右旋，为标配，可选左旋', 'READY', '0', '洗矿机(202604核对）', '18'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '11系列', '直线振动筛', 'ZKB-1156', 'ZKB-1156', 'SF19A.0A', '2620', '', '6150*2400*1530', '1100*5600', '6.16', '1', '-5～+5', '46181', '970', '20-120', '250', '2×7.5', 'YE3-160M-6-7.5kW-IP55', '筛体
振动器
隔振弹簧
支座
电动机', '喷水管、进料槽、出料槽等', '', '传动部可根据需要安装在任何一侧，标准配置为右侧；筛隙订货时确定', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '3'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '18系列', '直线振动筛', 'ZKB-1836', 'ZKB-1836', 'SF231.0(C0554)', '5590', '', '4560*3270*1910', '1800*3600', '6.48', '1', '-5～+5', '46181', '970', '40-300', '', '2×7.5', 'YE3-160M-6-7.5kW-B3-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '4'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '18系列', '直线振动筛', 'ZKB-1848', 'ZKB-1848', 'SF23001.0A', '5900', '', '5730*3250*1480', '1800*4800', '8.64', '1', '-5～+5', '46181', '970', '40-400', '', '2×11', 'YE3-160L-6-11kW-B3-T-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '5'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '18系列', '直线振动筛', '2ZKB-1848', '2ZKB-1848', 'SF22503.0', '8250', '', '5560*3310*1950', '', '', '2', '-5～+5', '46181', '985', '', '', '2×15', 'YE3-180L-6-15kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '2', '直线振动筛-260420更新', '6'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '18系列', '直线振动筛', '3ZKB-1848', '3ZKB-1848', 'SF220.0A', '11550', '', '5560*3310*2160', '', '', '3', '-5～+5', '46181', '985', '', '', '2×15', 'YE3-180L-6-15kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '2', '直线振动筛-260420更新', '7'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '18系列', '直线振动筛', 'ZKB-1860', 'ZKB-1860', 'SF228.0', '6570', '', '6940*3250*1540', '1800*6000', '10.8', '1', '-5～+5', '46181', '970', '50-450', '', '2×11', 'YE3-160L-6-11kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '8')
ON DUPLICATE KEY UPDATE product_kind=VALUES(product_kind), family=VALUES(family), series_name=VALUES(series_name), product_name=VALUES(product_name), model=VALUES(model), raw_model=VALUES(raw_model), drawing_no=VALUES(drawing_no), weight_kg=VALUES(weight_kg), quote_weight_t=VALUES(quote_weight_t), dimensions=VALUES(dimensions), main_spec=VALUES(main_spec), screen_area_m2=VALUES(screen_area_m2), deck_count=VALUES(deck_count), inclination=VALUES(inclination), amplitude=VALUES(amplitude), frequency=VALUES(frequency), capacity_tph=VALUES(capacity_tph), feed_size_mm=VALUES(feed_size_mm), power_kw=VALUES(power_kw), motor_model=VALUES(motor_model), standard_supply=VALUES(standard_supply), options_text=VALUES(options_text), transport_text=VALUES(transport_text), remarks=VALUES(remarks), quality_status=VALUES(quality_status), issue_count=VALUES(issue_count);

INSERT INTO sp_equipment_product (source_id, product_kind, family, series_name, product_name, model, raw_model, drawing_no, weight_kg, quote_weight_t, dimensions, main_spec, screen_area_m2, deck_count, inclination, amplitude, frequency, capacity_tph, feed_size_mm, power_kw, motor_model, standard_supply, options_text, transport_text, remarks, quality_status, issue_count, source_sheet, source_row) VALUES
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '18系列', '直线振动筛', '2ZKB-1860', '2ZKB-1860', 'SF232.0', '8900', '', '6940*3320*2160', '', '', '2', '-5～+5', '46181', '985', '', '', '2×15', 'YE3-180L-6-15kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '2', '直线振动筛-260420更新', '9'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '21系列', '直线振动筛', '2ZKB-2148', '2ZKB-2148', 'SF222YJ.0', '8450', '', '5670*3620*1900', '2100*4800', '10.08', '2', '-5～+5', '46181', '985', '50-500', '', '2×15', 'YE3-180L-6-15kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '10'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '21系列', '直线振动筛', '2ZKB-2154', '2ZKB-2154', 'SF221.0-YJ', '8900', '', '6270*3620*1830', '2100*5400', '11.34', '2', '-5～+5', '46181', '985', '50-520', '', '2×15', 'YE3-180L-6-15kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '11'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '21系列', '直线振动筛', '2ZKB-2160', '2ZKB-2160', 'SF23501.0', '10980', '', '6870*3700*1900', '2100*6000', '12.6', '2', '-5～+5', '46181', '970', '50-550', '', '2×18.5', 'YE3-200L1-6-18.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '12'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '24系列', '直线振动筛', '2ZKB-2448', '2ZKB-2448', 'SF24501.0', '9730', '', '5660*3930*1960', '2400*4800', '11.52', '2', '-5～+5', '46181', '985', '60-600', '', '2×15', 'YE3-180L-6-15kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '13'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '24系列', '直线振动筛', 'ZKB-2460', 'ZKB-2460', 'SF22901.0', '7850', '', '6920*3850*1500', '2400*6000', '14.4', '1', '-5～+5', '46181', '970', '60-600', '', '2×11', 'YE3-160L-6-11kW-B3-T-IP55', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '14'),
(@src_linear, 'linear-screen', 'ZKB型直线振动筛-干油振动器', '24系列', '直线振动筛', '2ZKB-2460', '2ZKB-2460', 'SF22401.0', '11700', '', '6930*3980*1930', '', '', '2', '-5～+5', '46181', '970', '', '', '2×18.5', 'YE3-200L1-6-18.5kW-IP55', '', '', '', '', 'NEEDS_REVIEW', '2', '直线振动筛-260420更新', '15'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '11系列', '直线振动筛', 'ZKJ-1145', 'ZKJ-1145', 'SF233.0(C1031)', '2690', '', '4990*1740*1390', '1100*4500', '4.95', '1', '-5～+5', '6～8', '1000', '20-100', '200', '2×2.9', 'MVE6500/1N-85A0', '筛体
隔振弹簧
支座
电动机', '喷水管、进料槽、出料槽等', '', '振动源电动机', 'READY', '0', '直线振动筛-260420更新', '20'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '12系列', '直线振动筛', 'ZKJ-1224', 'ZKJ-1224', 'SF227.0', '2050', '', '3200*1840*1450', '1200*2400', '2.88', '1', '-5～+5', '6～8', '1000', '20-150', '200', '2×2', 'MVE3800/1N-80A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '21'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '12系列', '直线振动筛', '2ZKJ-1224', '2ZKJ-1224', 'SF238.0', '1690', '', '3200*1840*1840', '', '', '2', '-5～+5', '6～8', '1000', '20-150', '200', '2×2.9', 'MVE6500/1N-85A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '22'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '12系列', '直线振动筛', 'ZKJ-1230', 'ZKJ-1230', 'SF23701.0', '2050', '', '3800*1840*1500', '1200*3000', '3.6', '1', '-5～+5', '6～8', '1000', '20-180', '200', '2×2.35', 'MVE4700/1N-80A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '23'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '12系列', '直线振动筛', 'ZKJ-1242', 'ZKJ-1242', 'SF23901.0', '2550', '', '4800*1820*1400', '1200*4200', '5.04', '1', '-5～+5', '6～8', '1000', '20-240', '200', '2×2.9', 'MVE6500/1N-85A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '24'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '12系列', '直线振动筛', 'ZKJ-1248', 'ZKJ-1248', 'SF24401.0', '3200', '', '5400*1820*1540', '1200*4800', '5.76', '1', '-5～+5', '6～8', '1000', '20-300', '200', '2×2.9', 'MVE6500/1N-85A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '25'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '15系列', '直线振动筛', 'ZKJ-1536', 'ZKJ-1536', 'SF210.0', '3450', '', '3900*2120*1720', '1500*3600', '5.4', '1', '-5～+5', '6～8', '1000', '30-300', '200', '2×5', 'MVE9000/1N-85A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '26'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '15系列', '直线振动筛', 'ZKJ-1548', 'ZKJ-1548', 'SF207.00', '4680', '', '5750*2250*1850', '1500*4800', '7.2', '1', '-5～+5', '6～8', '1000', '40-360', '200', '2×5', 'MVE9000/1N-85A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '27'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '15系列', '直线振动筛', '2ZKJ-1548', '2ZKJ-1548', 'SF204.00', '7600', '', '5750*2250*2290', '', '', '2', '-5～+5', '6～8', '1000', '', '200', '2×7', 'MVE13001/1N-90A0', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '28'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '18系列', '直线振动筛', 'ZKJ-1842', 'ZKJ-1842', 'SF236.0(C1563)', '5000', '', '5150*2560*1950', '1800*4200', '7.56', '1', '-5～+5', '6～8', '1000', '50-400', '250', '2×5', 'MVE9000/1N-85A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '29'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '18系列', '直线振动筛', 'ZKJ-1848', 'ZKJ-1848', 'SF202.0A', '5600', '', '5750*2570*1980', '1800*4800', '8.64', '1', '-5～+5', '6～8', '1000', '50-450', '250', '2×6', 'MVE10000/1N-90A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '30'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '18系列', '直线振动筛', '2ZKJ-1848', '2ZKJ-1848', 'SF201A.0A', '7450', '', '5750*2570*2390', '', '', '2', '-5～+5', '6～8', '1000', '', '250', '2×7', 'MVE13001/1N-90A0', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '31'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '21系列', '直线振动筛', 'ZKJ-2148', 'ZKJ-2148', 'SF206.0', '5820', '', '5700*2790*2230', '2100*4800', '10.08', '1', '-5～+5', '6～8', '1000', '50-500', '250', '2×7', 'MVE13001/1N-90A0', '', '', '', '', 'READY', '0', '直线振动筛-260420更新', '32'),
(@src_linear, 'linear-screen', 'ZKJ型直线振动筛-振动电机', '24系列', '直线振动筛', '2ZKJ-2460', '2ZKJ-2460', 'SF22404.0', '13400', '', '7000*3440*2530', '2400*6000', '14.4', '2', '-5～+5', '6～8', '1000', '68-600', '250', '4×8', 'SVE12500-1N-FD-100EC-A', '', '', '', '侧板振动电机', 'READY', '0', '直线振动筛-260420更新', '33'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '18系列', '直线振动筛', 'ZK-1848', 'ZK-1848', '', '5900', '', '5730*3250*1480', '1800*4800', '8.64', '1', '-5～+5', '6～8', '800～1000', '40-360', '250', '2x11', '选配4级或6级电机。', '筛体
激振器
隔振弹簧
支座
电动机', '喷水管、进料槽、出料槽、筛下料仓等', '', '传动部可根据需要安装在任何一侧，标准配置为右侧；筛隙订货时确定', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '38'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '18系列', '直线振动筛', '2ZK-1848', '2ZK-1848', '', '8500', '', '5560*3310*1950', '', '', '2', '-5～+5', '6～8', '', '', '', '2x15', '', '', '', '', '', 'NEEDS_REVIEW', '2', '直线振动筛-260420更新', '39'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '18系列', '直线振动筛', 'ZK-1860', 'ZK-1860', '', '8500', '', '7010*3610*2060', '1800*6000', '10.8', '1', '-5～+5', '6～8', '', '48-420', '', '2x11', '', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '40'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '18系列', '直线振动筛', '2ZK-1860', '2ZK-1860', 'SF24102.0', '11150', '', '7010*3610*2620', '', '', '2', '-5～+5', '6～8', '1000', '', '', '2×18.5', 'YE3-200L1-6-18.5kW-IP55', '', '', '', '6级电机，可选配4级电机减速', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '41')
ON DUPLICATE KEY UPDATE product_kind=VALUES(product_kind), family=VALUES(family), series_name=VALUES(series_name), product_name=VALUES(product_name), model=VALUES(model), raw_model=VALUES(raw_model), drawing_no=VALUES(drawing_no), weight_kg=VALUES(weight_kg), quote_weight_t=VALUES(quote_weight_t), dimensions=VALUES(dimensions), main_spec=VALUES(main_spec), screen_area_m2=VALUES(screen_area_m2), deck_count=VALUES(deck_count), inclination=VALUES(inclination), amplitude=VALUES(amplitude), frequency=VALUES(frequency), capacity_tph=VALUES(capacity_tph), feed_size_mm=VALUES(feed_size_mm), power_kw=VALUES(power_kw), motor_model=VALUES(motor_model), standard_supply=VALUES(standard_supply), options_text=VALUES(options_text), transport_text=VALUES(transport_text), remarks=VALUES(remarks), quality_status=VALUES(quality_status), issue_count=VALUES(issue_count);

INSERT INTO sp_equipment_product (source_id, product_kind, family, series_name, product_name, model, raw_model, drawing_no, weight_kg, quote_weight_t, dimensions, main_spec, screen_area_m2, deck_count, inclination, amplitude, frequency, capacity_tph, feed_size_mm, power_kw, motor_model, standard_supply, options_text, transport_text, remarks, quality_status, issue_count, source_sheet, source_row) VALUES
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '24系列', '直线振动筛', 'ZK-2460', 'ZK-2460', '', '9300', '', '7000*4270*2030', '2400*6000', '14.4', '1', '-5～+5', '6～8', '800～1000', '68-600', '', '2x15', '选配4级或6级电机。', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '42'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '24系列', '直线振动筛', '2ZK-2460', '2ZK-2460', 'SF22403.0', '13000', '', '7000*4270*2630', '', '', '2', '-5～+5', '6～8', '1000', '', '', '2×18.5', 'YE3-200L1-6-18.5kW-IP55', '', '', '', '6级电机，可选配4级电机减速', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '43'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '30系列', '直线振动筛', 'ZK-3060', 'ZK-3060', '', '10500', '', '7000*4930*2050', '3000*6000', '18', '1', '-5～+5', '6～8', '800～1000', '85-750', '', '2x15', '选配4级或6级电机。', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '44'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '30系列', '直线振动筛', '2ZK-3060', '2ZK-3060', '', '14500', '', '7000*4930*2700', '', '', '2', '-5～+5', '6～8', '', '', '', '2x22', '', '', '', '', '', 'NEEDS_REVIEW', '2', '直线振动筛-260420更新', '45'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '30系列', '直线振动筛', 'ZK-3072', 'ZK-3072', 'SF24001.0', '12300', '', '7870*4950*2980', '3000*7200', '21.6', '1', '-5～+5', '6～8', '900', '100-900', '', '2×18.5', 'YE4-180M-4-18.5kW-IP55', '', '', '', '4级电机减速，可选配6级电机', 'READY', '0', '直线振动筛-260420更新', '46'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '30系列', '直线振动筛', '2ZK-3072', '2ZK-3072', '', '15000', '', '7870*4950*3600', '', '', '2', '-5～+5', '6～8', '800～1000', '', '', '2x30', '选配4级或6级电机。', '', '', '', '传动部可根据需要安装在任何一侧，标准配置为右侧；筛隙订货时确定', 'NEEDS_REVIEW', '2', '直线振动筛-260420更新', '47'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '36系列', '直线振动筛', 'ZK-3672', 'ZK-3672', '', '14600', '', '7870*5580*3000', '3600*7200', '25.92', '1', '-5～+5', '6～8', '', '120-1100', '', '2x22', '', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '48'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '36系列', '直线振动筛', '2ZK-3672', '2ZK-3672', '', '18000', '', '7870*5580*3700', '', '', '2', '-5～+5', '6～8', '', '', '', '2x37', '', '', '', '', '', 'NEEDS_REVIEW', '2', '直线振动筛-260420更新', '49'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '36系列', '直线振动筛', 'ZK-3685', 'ZK-3685', '', '17500', '', '9440*5820*3100', '3600*8500', '30.6', '1', '-5～+5', '6～8', '', '120-1300', '', '2x30', '', '', '', '', '', 'NEEDS_REVIEW', '1', '直线振动筛-260420更新', '50'),
(@src_linear, 'linear-screen', 'ZK型直线振动筛-盘式稀油激振器', '36系列', '直线振动筛', '2ZK-3685', '2ZK-3685', '', '22000', '', '9440*5820*3800', '', '', '2', '-5～+5', '6～8', '', '', '', '2x45', '', '', '', '', '', 'NEEDS_REVIEW', '2', '直线振动筛-260420更新', '51')
ON DUPLICATE KEY UPDATE product_kind=VALUES(product_kind), family=VALUES(family), series_name=VALUES(series_name), product_name=VALUES(product_name), model=VALUES(model), raw_model=VALUES(raw_model), drawing_no=VALUES(drawing_no), weight_kg=VALUES(weight_kg), quote_weight_t=VALUES(quote_weight_t), dimensions=VALUES(dimensions), main_spec=VALUES(main_spec), screen_area_m2=VALUES(screen_area_m2), deck_count=VALUES(deck_count), inclination=VALUES(inclination), amplitude=VALUES(amplitude), frequency=VALUES(frequency), capacity_tph=VALUES(capacity_tph), feed_size_mm=VALUES(feed_size_mm), power_kw=VALUES(power_kw), motor_model=VALUES(motor_model), standard_supply=VALUES(standard_supply), options_text=VALUES(options_text), transport_text=VALUES(transport_text), remarks=VALUES(remarks), quality_status=VALUES(quality_status), issue_count=VALUES(issue_count);

DELETE qi FROM sp_equipment_quality_issue qi
JOIN sp_equipment_product p ON p.id=qi.product_id
WHERE p.source_id IN (@src_circular, @src_washer, @src_linear);

INSERT INTO sp_equipment_quality_issue (product_id, issue_code, issue_message, review_status)
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=4
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=4
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=4
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=6
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=8
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=8
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=8
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=9
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=9
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=9
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=11
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=12
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=12
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=12
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=14
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=20
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=21
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=22
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=23
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=24
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=25
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=25
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=25
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=27
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=28
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=28
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=28
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=30
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=31
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=33
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=33
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=33
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=34
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=34
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=34
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=38
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=40
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=41
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=44
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=45
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=46
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=47
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=48
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=49
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=51
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=52
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=52
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=53
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=53
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=53
ON DUPLICATE KEY UPDATE issue_message=VALUES(issue_message), review_status='OPEN';

INSERT INTO sp_equipment_quality_issue (product_id, issue_code, issue_message, review_status)
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=54
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=54
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=54
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=56
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=57
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=58
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=59
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=60
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=60
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=60
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=61
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=61
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=61
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=62
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=62
UNION ALL
SELECT p.id, 'MISSING_WEIGHT', '缺少重量', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_circular AND p.source_sheet='Sheet1' AND p.source_row=62
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=3
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=4
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=5
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=6
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=6
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=7
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=7
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=8
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=9
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=9
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=10
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=11
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=12
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=13
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=14
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=15
UNION ALL
SELECT p.id, 'AMPLITUDE_DATE_SERIAL', '双振幅疑似被 Excel 误识别为日期序号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=15
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=28
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=31
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=38
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=39
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=39
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=40
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=41
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=42
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=43
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=44
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=45
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=45
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=47
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=47
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=48
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=49
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=49
ON DUPLICATE KEY UPDATE issue_message=VALUES(issue_message), review_status='OPEN';

INSERT INTO sp_equipment_quality_issue (product_id, issue_code, issue_message, review_status)
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=50
UNION ALL
SELECT p.id, 'MISSING_DRAWING_NO', '缺少图号', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=51
UNION ALL
SELECT p.id, 'MISSING_CAPACITY', '缺少处理能力', 'OPEN' FROM sp_equipment_product p WHERE p.source_id=@src_linear AND p.source_sheet='直线振动筛-260420更新' AND p.source_row=51
ON DUPLICATE KEY UPDATE issue_message=VALUES(issue_message), review_status='OPEN';

COMMIT;

SELECT COUNT(*) AS source_file_count FROM sp_product_source_file;
SELECT product_kind, COUNT(*) AS product_count, SUM(quality_status='NEEDS_REVIEW') AS needs_review_count FROM sp_equipment_product GROUP BY product_kind ORDER BY product_kind;
SELECT COUNT(*) AS quality_issue_count FROM sp_equipment_quality_issue WHERE review_status='OPEN';

