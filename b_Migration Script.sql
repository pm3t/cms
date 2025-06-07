# Church Management System - Schema & Migration Script

CREATE SCHEMA IF NOT EXISTS `church_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE `church_db` ;

-- -----------------------------------------------------
-- Table `organizations`
-- Kunci utama: `id` (BIGINT)
-- Deskripsi: Tabel ini menyimpan informasi tentang setiap organisasi (gereja) yang menggunakan sistem.
-- Ini adalah tabel inti untuk arsitektur multi-tenant.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `organizations` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NULL,
  `phone` VARCHAR(50) NULL,
  `address` TEXT NULL,
  `city` VARCHAR(100) NULL,
  `state` VARCHAR(100) NULL,
  `country` VARCHAR(100) NULL,
  `postal_code` VARCHAR(20) NULL,
  `timezone` VARCHAR(50) NULL,
  `currency` VARCHAR(10) NULL,
  `language` VARCHAR(10) NULL,
  `status` VARCHAR(50) DEFAULT 'active' NOT NULL,
  `logo_url` TEXT NULL,
  `branding_config` JSON NULL, -- Untuk menyimpan konfigurasi branding dalam format JSON
  `system_preferences` JSON NULL, -- Untuk menyimpan preferensi sistem dalam format JSON
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `name_UNIQUE` (`name` ASC) VISIBLE,
  UNIQUE INDEX `email_UNIQUE` (`email` ASC) VISIBLE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `branches`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel ini menyimpan informasi tentang cabang-cabang (kampus) dari setiap organisasi.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `branches` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `code` VARCHAR(50) NULL,
  `address` TEXT NULL,
  `city` VARCHAR(100) NULL,
  `phone` VARCHAR(50) NULL,
  `email` VARCHAR(255) NULL,
  `is_main` BOOLEAN NOT NULL DEFAULT 0, -- 1 untuk cabang utama, 0 untuk lainnya
  `is_active` BOOLEAN NOT NULL DEFAULT 1, -- Status aktif/non-aktif cabang
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_branches_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_branches_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `users`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel ini menyimpan informasi detail pengguna (user) sistem, termasuk kredensial otentikasi.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `username` VARCHAR(255) NOT NULL, -- Bisa digunakan sebagai alternatif login
  `password_hash` VARCHAR(255) NOT NULL, -- Hash kata sandi
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NULL,
  `phone` VARCHAR(50) NULL,
  `avatar_url` TEXT NULL,
  `email_verified` BOOLEAN NOT NULL DEFAULT 0,
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `require_2fa` BOOLEAN NOT NULL DEFAULT 0, -- Kebutuhan autentikasi dua faktor
  `last_login_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `email_UNIQUE` (`email` ASC) VISIBLE,
  UNIQUE INDEX `username_UNIQUE` (`username` ASC) VISIBLE,
  INDEX `fk_users_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_users_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `roles`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel ini mendefinisikan peran-peran yang ada dalam sistem (misalnya, Admin, Staf, Anggota).
-- Peran bisa spesifik per organisasi.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `roles` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `slug` VARCHAR(100) NULL, -- Nama unik, contoh: 'admin', 'member'
  `description` TEXT NULL,
  `is_system_role` BOOLEAN NOT NULL DEFAULT 0, -- Apakah peran ini adalah peran bawaan sistem
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
 -- UNIQUE INDEX `organization_id_slug_UNIQUE` (`organization_id` ASC, `slug` ASC) VISIBLE,
  INDEX `fk_roles_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_roles_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `permissions`
-- Kunci utama: `id` (BIGINT)
-- Deskripsi: Tabel ini mendefinisikan izin-izin spesifik yang dapat diberikan dalam sistem (misalnya, 'create_user', 'view_finances').
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `permissions` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `slug` VARCHAR(100) NOT NULL, -- Nama unik, contoh: 'users.create', 'finances.view'
  `module` VARCHAR(100) NULL, -- Modul terkait, contoh: 'users', 'finances'
  `description` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `slug_UNIQUE` (`slug` ASC) VISIBLE
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `user_roles`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `user_id` merujuk ke `users.id`, `role_id` merujuk ke `roles.id`
-- Deskripsi: Tabel pivot untuk mengaitkan pengguna dengan peran. Seorang pengguna dapat memiliki banyak peran.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_roles` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `role_id` BIGINT NOT NULL,
  `assigned_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `user_id_role_id_UNIQUE` (`user_id` ASC, `role_id` ASC) VISIBLE,
  INDEX `fk_user_roles_users_idx` (`user_id` ASC) VISIBLE,
  INDEX `fk_user_roles_roles_idx` (`role_id` ASC) VISIBLE,
  CONSTRAINT `fk_user_roles_users`
    FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_user_roles_roles`
    FOREIGN KEY (`role_id`)
    REFERENCES `roles` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `role_permissions`
-- Deskripsi: Tabel join untuk hubungan Many-to-Many antara roles dan permissions.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `role_permissions` (
  `role_id` BIGINT NOT NULL,
  `permission_id` BIGINT NOT NULL,
  `assigned_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`, `permission_id`),
  INDEX `fk_role_permissions_permissions_idx` (`permission_id` ASC) VISIBLE,
  CONSTRAINT `fk_role_permissions_roles`
    FOREIGN KEY (`role_id`)
    REFERENCES `roles` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_role_permissions_permissions`
    FOREIGN KEY (`permission_id`)
    REFERENCES `permissions` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `user_sessions`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `user_id` merujuk ke `users.id`
-- Deskripsi: Tabel untuk melacak sesi pengguna yang sedang aktif, berguna untuk manajemen sesi dan keamanan.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_sessions` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `session_token` VARCHAR(255) NOT NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `expires_at` TIMESTAMP NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `session_token_UNIQUE` (`session_token` ASC) VISIBLE,
  INDEX `fk_user_sessions_users_idx` (`user_id` ASC) VISIBLE,
  CONSTRAINT `fk_user_sessions_users`
    FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `families`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `head_member_id` merujuk ke `members.id` (logis)
-- Deskripsi: Tabel ini menyimpan informasi tentang keluarga dalam suatu organisasi.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `families` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `family_name` VARCHAR(255) NOT NULL,
  `family_code` VARCHAR(50) NULL, -- Kode unik untuk keluarga
  `head_member_id` BIGINT NULL, -- Anggota keluarga yang dianggap kepala keluarga (FK logis, akan ditambahkan setelah `members`)
  `address` TEXT NULL,
  `phone` VARCHAR(50) NULL,
  `email` VARCHAR(255) NULL,
  `custom_fields` JSON NULL, -- Bidang kustom dalam format JSON
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_families_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_families_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `members`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `user_id` merujuk ke `users.id` (jika ada akun user terkait), `family_id` merujuk ke `families.id`
-- Deskripsi: Tabel ini menyimpan informasi detail tentang anggota gereja.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `members` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `user_id` BIGINT NULL, -- Opsional: jika anggota memiliki akun user di sistem
  `member_number` VARCHAR(100) NULL, -- Nomor anggota unik
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NULL,
  `middle_name` VARCHAR(100) NULL,
  `nickname` VARCHAR(100) NULL,
  `gender` ENUM('Male', 'Female', 'Other') NULL,
  `date_of_birth` DATE NULL,
  `phone` VARCHAR(50) NULL,
  `email` VARCHAR(255) NULL,
  `address` TEXT NULL,
  `city` VARCHAR(100) NULL,
  `state` VARCHAR(100) NULL,
  `postal_code` VARCHAR(20) NULL,
  `marital_status` VARCHAR(50) NULL,
  `occupation` VARCHAR(255) NULL,
  `education` VARCHAR(255) NULL,
  `photo_url` TEXT NULL,
  `membership_status` VARCHAR(50) DEFAULT 'active' NOT NULL, -- Contoh: 'active', 'inactive', 'transferred'
  `member_category` VARCHAR(100) NULL, -- Contoh: 'Dewasa', 'Remaja', 'Anak'
  `joined_date` DATE NULL,
  `baptism_date` DATE NULL,
  `confirmation_date` DATE NULL,
  `family_id` BIGINT NULL,
  `is_family_head` BOOLEAN NOT NULL DEFAULT 0, -- Apakah anggota ini adalah kepala keluarga
  `emergency_contacts` JSON NULL, -- Kontak darurat dalam format JSON
  `custom_fields` JSON NULL, -- Bidang kustom dalam format JSON
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_member_number_UNIQUE` (`organization_id` ASC, `member_number` ASC) VISIBLE,
  INDEX `fk_members_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_members_branches_idx` (`branch_id` ASC) VISIBLE,
  INDEX `fk_members_users_idx` (`user_id` ASC) VISIBLE,
  INDEX `fk_members_families_idx` (`family_id` ASC) VISIBLE,
  CONSTRAINT `fk_members_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_members_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_members_users`
    FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_members_families`
    FOREIGN KEY (`family_id`)
    REFERENCES `families` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;

-- Tambahkan kunci asing `head_member_id` ke tabel `families` setelah tabel `members` dibuat
ALTER TABLE `families`
  ADD CONSTRAINT `fk_families_members`
    FOREIGN KEY (`head_member_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE;


-- -----------------------------------------------------
-- Table `member_relationships`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `member_id` merujuk ke `members.id`, `related_member_id` merujuk ke `members.id`
-- Deskripsi: Tabel ini merekam hubungan antar anggota (misalnya, suami-istri, orang tua-anak).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `member_relationships` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `member_id` BIGINT NOT NULL,
  `related_member_id` BIGINT NOT NULL,
  `relationship_type` VARCHAR(100) NOT NULL, -- Contoh: 'spouse', 'parent', 'child', 'sibling'
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `member_id_related_member_id_UNIQUE` (`member_id` ASC, `related_member_id` ASC, `relationship_type` ASC) VISIBLE,
  INDEX `fk_member_relationships_members1_idx` (`member_id` ASC) VISIBLE,
  INDEX `fk_member_relationships_members2_idx` (`related_member_id` ASC) VISIBLE,
  CONSTRAINT `fk_member_relationships_members1`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_member_relationships_members2`
    FOREIGN KEY (`related_member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `announcements`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `created_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk pengumuman atau berita yang akan ditampilkan kepada anggota.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `announcements` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL, -- Opsional: pengumuman bisa spesifik untuk cabang
  `created_by` BIGINT NULL, -- User yang membuat pengumuman
  `title` VARCHAR(255) NOT NULL,
  `content` TEXT NOT NULL,
  `priority` ENUM('Low', 'Medium', 'High', 'Urgent') DEFAULT 'Medium' NOT NULL,
  `status` ENUM('Draft', 'Published', 'Archived', 'Scheduled') DEFAULT 'Draft' NOT NULL,
  `publish_date` DATE NULL, -- Tanggal mulai publikasi
  `expire_date` DATE NULL, -- Tanggal berakhir publikasi
  `target_audience` JSON NULL, -- Untuk menargetkan audiens tertentu (misal: 'youth', 'leaders')
  `send_notification` BOOLEAN DEFAULT 0 NOT NULL, -- Apakah akan mengirim notifikasi push/email
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_announcements_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_announcements_branches_idx` (`branch_id` ASC) VISIBLE,
  INDEX `fk_announcements_users_idx` (`created_by` ASC) VISIBLE,
  CONSTRAINT `fk_announcements_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_announcements_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_announcements_users`
    FOREIGN KEY (`created_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `communication_templates`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Template untuk komunikasi (email, SMS, notifikasi) yang dapat digunakan ulang.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `communication_templates` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `type` ENUM('Email', 'SMS', 'Push Notification') NOT NULL,
  `subject` VARCHAR(255) NULL, -- Subjek untuk email
  `content` TEXT NOT NULL, -- Isi template, bisa HTML untuk email
  `variables` JSON NULL, -- Variabel yang bisa disisipkan dalam template (misal: {'member_name': 'John Doe'})
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_name_UNIQUE` (`organization_id` ASC, `name` ASC) VISIBLE,
  INDEX `fk_communication_templates_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_communication_templates_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `communications`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `template_id` merujuk ke `communication_templates.id`,
-- `sent_by` merujuk ke `users.id`
-- Deskripsi: Log pengiriman komunikasi (email, SMS, notifikasi).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `communications` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `template_id` BIGINT NULL, -- Template yang digunakan, opsional jika komunikasi ad-hoc
  `sent_by` BIGINT NULL, -- User yang mengirim komunikasi
  `type` ENUM('Email', 'SMS', 'Push Notification') NOT NULL,
  `subject` VARCHAR(255) NULL,
  `content` TEXT NOT NULL, -- Isi komunikasi yang sebenarnya (setelah diisi variabel)
  `recipients` JSON NOT NULL, -- Daftar penerima (misal: [{'member_id': 1}, {'email': 'test@example.com'}])
  `status` ENUM('Pending', 'Sent', 'Failed', 'Scheduled') DEFAULT 'Pending' NOT NULL,
  `sent_at` DATETIME NULL,
  `delivery_stats` JSON NULL, -- Statistik pengiriman (misal: 'opened', 'clicked', 'bounced')
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_communications_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_communications_communication_templates_idx` (`template_id` ASC) VISIBLE,
  INDEX `fk_communications_users_idx` (`sent_by` ASC) VISIBLE,
  CONSTRAINT `fk_communications_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_communications_communication_templates`
    FOREIGN KEY (`template_id`)
    REFERENCES `communication_templates` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_communications_users`
    FOREIGN KEY (`sent_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `offerings`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `member_id` merujuk ke `members.id`, `recorded_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mencatat persembahan yang diterima dari anggota.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `offerings` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `member_id` BIGINT NULL, -- Opsional: bisa anonymous
  `offering_type` VARCHAR(100) NOT NULL, -- Contoh: 'Tithes', 'General Offering', 'Special Offering'
  `amount` DECIMAL(15,2) NOT NULL,
  `currency` VARCHAR(10) DEFAULT 'IDR' NOT NULL,
  `offering_date` DATE NOT NULL,
  `payment_method` VARCHAR(100) NULL, -- Contoh: 'Cash', 'Bank Transfer', 'Online Payment'
  `reference_number` VARCHAR(255) NULL, -- Nomor referensi transaksi
  `notes` TEXT NULL,
  `recorded_by` BIGINT NULL, -- User yang mencatat persembahan
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_offerings_date` (`offering_date` ASC) VISIBLE,
  INDEX `fk_offerings_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_offerings_branches_idx` (`branch_id` ASC) VISIBLE,
  INDEX `fk_offerings_members_idx` (`member_id` ASC) VISIBLE,
  INDEX `fk_offerings_users_idx` (`recorded_by` ASC) VISIBLE,
  CONSTRAINT `fk_offerings_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_offerings_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_offerings_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_offerings_users`
    FOREIGN KEY (`recorded_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `donation_projects`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel untuk mengelola proyek-proyek donasi (misalnya, pembangunan gereja, misi sosial).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `donation_projects` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `target_amount` DECIMAL(15,2) NULL,
  `current_amount` DECIMAL(15,2) DEFAULT 0.00 NOT NULL,
  `start_date` DATE NULL,
  `end_date` DATE NULL,
  `status` ENUM('Planned', 'Active', 'Completed', 'Cancelled') DEFAULT 'Planned' NOT NULL,
  `image_url` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_donation_projects_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_donation_projects_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `donations`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `member_id` merujuk ke `members.id`,
-- `project_id` merujuk ke `donation_projects.id`
-- Deskripsi: Tabel untuk mencatat donasi yang diterima untuk proyek tertentu.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `donations` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `member_id` BIGINT NULL, -- Anggota yang berdonasi, opsional (bisa anonymous)
  `project_id` BIGINT NULL, -- Proyek donasi terkait, opsional (bisa donasi umum)
  `donation_type` VARCHAR(100) NULL, -- Contoh: 'Cash', 'In-kind', 'Online'
  `amount` DECIMAL(15,2) NOT NULL,
  `currency` VARCHAR(10) DEFAULT 'IDR' NOT NULL,
  `donation_date` DATE NOT NULL,
  `payment_method` VARCHAR(100) NULL,
  `reference_number` VARCHAR(255) NULL,
  `status` ENUM('Pending', 'Completed', 'Refunded', 'Cancelled') DEFAULT 'Completed' NOT NULL,
  `notes` TEXT NULL,
  `is_anonymous` BOOLEAN DEFAULT 0 NOT NULL, -- Apakah donasi dilakukan secara anonim
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_donations_date` (`donation_date` ASC) VISIBLE,
  INDEX `fk_donations_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_donations_members_idx` (`member_id` ASC) VISIBLE,
  INDEX `fk_donations_donation_projects_idx` (`project_id` ASC) VISIBLE,
  CONSTRAINT `fk_donations_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_donations_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_donations_donation_projects`
    FOREIGN KEY (`project_id`)
    REFERENCES `donation_projects` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `pledges`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `member_id` merujuk ke `members.id`,
-- `project_id` merujuk ke `donation_projects.id`
-- Deskripsi: Tabel untuk mencatat janji donasi (pledge) dari anggota.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `pledges` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `member_id` BIGINT NOT NULL,
  `project_id` BIGINT NULL, -- Proyek donasi yang dijanjikan, opsional
  `pledge_amount` DECIMAL(15,2) NOT NULL,
  `paid_amount` DECIMAL(15,2) DEFAULT 0.00 NOT NULL,
  `pledge_date` DATE NOT NULL,
  `due_date` DATE NULL,
  `frequency` ENUM('One-time', 'Weekly', 'Monthly', 'Quarterly', 'Annually') DEFAULT 'One-time' NOT NULL,
  `status` ENUM('Pending', 'Fulfilled', 'Partially Fulfilled', 'Cancelled') DEFAULT 'Pending' NOT NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_pledges_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_pledges_members_idx` (`member_id` ASC) VISIBLE,
  INDEX `fk_pledges_donation_projects_idx` (`project_id` ASC) VISIBLE,
  CONSTRAINT `fk_pledges_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_pledges_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_pledges_donation_projects`
    FOREIGN KEY (`project_id`)
    REFERENCES `donation_projects` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `budgets`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`
-- Deskripsi: Tabel untuk mengelola anggaran tahunan atau periodik.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `budgets` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL, -- Opsional: anggaran bisa spesifik untuk cabang
  `name` VARCHAR(255) NOT NULL, -- Nama anggaran (misal: 'Anggaran 2024')
  `year` INT NOT NULL,
  `total_amount` DECIMAL(15,2) NOT NULL,
  `status` ENUM('Draft', 'Approved', 'Archived') DEFAULT 'Draft' NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_year_branch_id_UNIQUE` (`organization_id` ASC, `year` ASC, `branch_id` ASC) VISIBLE,
  INDEX `fk_budgets_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_budgets_branches_idx` (`branch_id` ASC) VISIBLE,
  CONSTRAINT `fk_budgets_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_budgets_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `budget_categories`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `budget_id` merujuk ke `budgets.id`
-- Deskripsi: Tabel untuk kategori-kategori anggaran di bawah suatu anggaran utama.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `budget_categories` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `budget_id` BIGINT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `allocated_amount` DECIMAL(15,2) NOT NULL,
  `spent_amount` DECIMAL(15,2) DEFAULT 0.00 NOT NULL,
  `description` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_budget_categories_budgets_idx` (`budget_id` ASC) VISIBLE,
  CONSTRAINT `fk_budget_categories_budgets`
    FOREIGN KEY (`budget_id`)
    REFERENCES `budgets` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `expenses`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `category_id` merujuk ke `budget_categories.id`, `approved_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mencatat pengeluaran.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `expenses` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `category_id` BIGINT NULL, -- Kategori anggaran terkait
  `description` TEXT NOT NULL,
  `amount` DECIMAL(15,2) NOT NULL,
  `currency` VARCHAR(10) DEFAULT 'IDR' NOT NULL,
  `expense_date` DATE NOT NULL,
  `payment_method` VARCHAR(100) NULL,
  `reference_number` VARCHAR(255) NULL,
  `receipt_url` TEXT NULL, -- URL bukti pembayaran
  `approved_by` BIGINT NULL, -- User yang menyetujui pengeluaran
  `status` ENUM('Pending', 'Approved', 'Rejected', 'Paid') DEFAULT 'Pending' NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_expenses_date` (`expense_date` ASC) VISIBLE,
  INDEX `fk_expenses_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_expenses_branches_idx` (`branch_id` ASC) VISIBLE,
  INDEX `fk_expenses_budget_categories_idx` (`category_id` ASC) VISIBLE,
  INDEX `fk_expenses_users_idx` (`approved_by` ASC) VISIBLE,
  CONSTRAINT `fk_expenses_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_expenses_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_expenses_budget_categories`
    FOREIGN KEY (`category_id`)
    REFERENCES `budget_categories` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_expenses_users`
    FOREIGN KEY (`approved_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `event_types`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel untuk mendefinisikan jenis-jenis acara yang dapat dibuat oleh organisasi.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `event_types` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL, -- Untuk soft delete
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_name_UNIQUE` (`organization_id` ASC, `name` ASC) VISIBLE,
  INDEX `fk_event_types_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_event_types_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `configurable_statuses`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel untuk status yang dapat dikonfigurasi oleh pengguna untuk berbagai entitas (misal: status event, status anggota).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `configurable_statuses` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `entity_type` VARCHAR(100) NOT NULL, -- Contoh: 'Event', 'Member', 'Task'
  `status_name` VARCHAR(100) NOT NULL,
  `status_code` VARCHAR(50) NOT NULL, -- Kode unik untuk status, misal 'PENDING', 'APPROVED'
  `description` TEXT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `sort_order` INT NULL, -- Urutan tampilan status
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` TIMESTAMP NULL, -- Untuk soft delete
  PRIMARY KEY (`id`),
  UNIQUE INDEX `org_entity_type_status_code_UNIQUE` (`organization_id` ASC, `entity_type` ASC, `status_code` ASC) VISIBLE,
  INDEX `fk_configurable_statuses_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_configurable_statuses_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `events`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `event_type_id` merujuk ke `event_types.id`, `status_id` merujuk ke `configurable_statuses.id` (untuk status event),
-- `created_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mengelola acara atau kegiatan gereja.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `events` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `event_type_id` BIGINT NULL, -- Jenis acara
  `start_datetime` DATETIME NOT NULL,
  `end_datetime` DATETIME NOT NULL,
  `location` VARCHAR(255) NULL,
  `capacity` INT NULL,
  `registered_count` INT DEFAULT 0 NOT NULL,
  `requires_registration` BOOLEAN NOT NULL DEFAULT 0,
  `registration_fee` DECIMAL(15,2) DEFAULT 0.00 NULL,
  `status_id` BIGINT NULL, -- Menggunakan configurable_statuses untuk status
  `image_url` TEXT NULL,
  `created_by` BIGINT NULL,
  `custom_fields` JSON NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_events_datetime` (`start_datetime` ASC, `end_datetime` ASC) VISIBLE,
  INDEX `fk_events_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_events_branches_idx` (`branch_id` ASC) VISIBLE,
  INDEX `fk_events_event_types_idx` (`event_type_id` ASC) VISIBLE,
  INDEX `fk_events_configurable_statuses_idx` (`status_id` ASC) VISIBLE,
  INDEX `fk_events_users_idx` (`created_by` ASC) VISIBLE,
  CONSTRAINT `fk_events_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_events_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_events_event_types`
    FOREIGN KEY (`event_type_id`)
    REFERENCES `event_types` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_events_configurable_statuses`
    FOREIGN KEY (`status_id`)
    REFERENCES `configurable_statuses` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_events_users`
    FOREIGN KEY (`created_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `event_registrations`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `event_id` merujuk ke `events.id`, `member_id` merujuk ke `members.id`
-- Deskripsi: Tabel untuk mencatat pendaftaran anggota atau tamu untuk suatu acara.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `event_registrations` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `event_id` BIGINT NOT NULL,
  `member_id` BIGINT NULL, -- Anggota yang mendaftar (opsional, bisa tamu)
  `guest_name` VARCHAR(255) NULL, -- Nama tamu jika bukan anggota
  `guest_email` VARCHAR(255) NULL,
  `guest_phone` VARCHAR(50) NULL,
  `status` ENUM('Registered', 'Attended', 'Cancelled') DEFAULT 'Registered' NOT NULL,
  `registered_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fee_paid` DECIMAL(15,2) DEFAULT 0.00 NULL,
  `payment_status` ENUM('Pending', 'Paid', 'Refunded') DEFAULT 'Pending' NULL,
  `notes` TEXT NULL,
  `custom_responses` JSON NULL, -- Jawaban untuk pertanyaan kustom saat pendaftaran
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `event_member_guest_UNIQUE` (`event_id` ASC, `member_id` ASC, `guest_email` ASC) VISIBLE, -- Unik kombinasi event-member atau event-guest_email
  INDEX `fk_event_registrations_events_idx` (`event_id` ASC) VISIBLE,
  INDEX `fk_event_registrations_members_idx` (`member_id` ASC) VISIBLE,
  CONSTRAINT `fk_event_registrations_events`
    FOREIGN KEY (`event_id`)
    REFERENCES `events` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_event_registrations_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `event_attendance`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `event_id` merujuk ke `events.id`, `member_id` merujuk ke `members.id`,
-- `checked_in_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mencatat kehadiran anggota atau tamu di acara.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `event_attendance` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `event_id` BIGINT NOT NULL,
  `member_id` BIGINT NULL, -- Anggota yang hadir (jika ada pendaftaran terkait member)
  `check_in_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `check_out_time` DATETIME NULL,
  `check_in_method` VARCHAR(100) NULL, -- Contoh: 'Manual', 'QR Code', 'System'
  `checked_in_by` BIGINT NULL, -- User yang melakukan check-in
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `event_id_member_id_UNIQUE` (`event_id` ASC, `member_id` ASC) VISIBLE, -- Hanya satu entri kehadiran per member per event
  INDEX `fk_event_attendance_events_idx` (`event_id` ASC) VISIBLE,
  INDEX `fk_event_attendance_members_idx` (`member_id` ASC) VISIBLE,
  INDEX `fk_event_attendance_users_idx` (`checked_in_by` ASC) VISIBLE,
  CONSTRAINT `fk_event_attendance_events`
    FOREIGN KEY (`event_id`)
    REFERENCES `events` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_event_attendance_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_event_attendance_users`
    FOREIGN KEY (`checked_in_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `services`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `led_by` merujuk ke `members.id` (logis, karena pemimpin layanan biasanya anggota)
-- Deskripsi: Tabel untuk jadwal dan detail kebaktian atau layanan gereja.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `services` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `name` VARCHAR(255) NOT NULL,
  `service_type` VARCHAR(100) NULL, -- Contoh: 'Sunday Service', 'Midweek Prayer', 'Youth Service'
  `service_datetime` DATETIME NOT NULL,
  `location` VARCHAR(255) NULL,
  `expected_attendance` INT NULL,
  `actual_attendance` INT NULL,
  `status` ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled' NOT NULL,
  `led_by` BIGINT NULL, -- Anggota yang memimpin layanan
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_services_datetime` (`service_datetime` ASC) VISIBLE,
  INDEX `fk_services_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_services_branches_idx` (`branch_id` ASC) VISIBLE,
  INDEX `fk_services_members_idx` (`led_by` ASC) VISIBLE,
  CONSTRAINT `fk_services_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_services_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_services_members`
    FOREIGN KEY (`led_by`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `service_attendance`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `service_id` merujuk ke `services.id`, `member_id` merujuk ke `members.id`,
-- `checked_in_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mencatat kehadiran anggota di suatu kebaktian.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `service_attendance` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `service_id` BIGINT NOT NULL,
  `member_id` BIGINT NOT NULL,
  `check_in_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `check_in_method` VARCHAR(100) NULL, -- Contoh: 'Manual', 'QR Code'
  `checked_in_by` BIGINT NULL, -- User yang melakukan check-in
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `service_id_member_id_UNIQUE` (`service_id` ASC, `member_id` ASC) VISIBLE,
  INDEX `fk_service_attendance_services_idx` (`service_id` ASC) VISIBLE,
  INDEX `fk_service_attendance_members_idx` (`member_id` ASC) VISIBLE,
  INDEX `fk_service_attendance_users_idx` (`checked_in_by` ASC) VISIBLE,
  CONSTRAINT `fk_service_attendance_services`
    FOREIGN KEY (`service_id`)
    REFERENCES `services` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_service_attendance_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_service_attendance_users`
    FOREIGN KEY (`checked_in_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `small_groups`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `leader_id` merujuk ke `members.id`, `co_leader_id` merujuk ke `members.id`
-- Deskripsi: Tabel untuk mengelola kelompok kecil (small group) atau komunitas.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `small_groups` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `name` VARCHAR(255) NOT NULL,
  `group_type` VARCHAR(100) NULL, -- Contoh: 'Cell Group', 'Youth Group', 'Interest Group'
  `description` TEXT NULL,
  `leader_id` BIGINT NULL, -- Anggota yang menjadi pemimpin kelompok
  `co_leader_id` BIGINT NULL, -- Anggota yang menjadi co-pemimpin
  `meeting_schedule` VARCHAR(255) NULL, -- Deskripsi jadwal pertemuan (misal: 'Every Tuesday, 7 PM')
  `meeting_location` VARCHAR(255) NULL,
  `max_members` INT NULL,
  `current_members` INT DEFAULT 0 NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_small_groups_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_small_groups_branches_idx` (`branch_id` ASC) VISIBLE,
  INDEX `fk_small_groups_leader_idx` (`leader_id` ASC) VISIBLE,
  INDEX `fk_small_groups_co_leader_idx` (`co_leader_id` ASC) VISIBLE,
  CONSTRAINT `fk_small_groups_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_small_groups_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_small_groups_leader`
    FOREIGN KEY (`leader_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_small_groups_co_leader`
    FOREIGN KEY (`co_leader_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `group_members`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `group_id` merujuk ke `small_groups.id`, `member_id` merujuk ke `members.id`
-- Deskripsi: Tabel pivot untuk mengaitkan anggota dengan kelompok kecil.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `group_members` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `group_id` BIGINT NOT NULL,
  `member_id` BIGINT NOT NULL,
  `role` VARCHAR(100) NULL, -- Peran dalam kelompok (misal: 'Member', 'Secretary')
  `joined_date` DATE NOT NULL DEFAULT (CURRENT_DATE),
  `left_date` DATE NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `group_id_member_id_UNIQUE` (`group_id` ASC, `member_id` ASC) VISIBLE,
  INDEX `fk_group_members_small_groups_idx` (`group_id` ASC) VISIBLE,
  INDEX `fk_group_members_members_idx` (`member_id` ASC) VISIBLE,
  CONSTRAINT `fk_group_members_small_groups`
    FOREIGN KEY (`group_id`)
    REFERENCES `small_groups` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_group_members_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `group_meetings`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `group_id` merujuk ke `small_groups.id`, `led_by` merujuk ke `members.id`
-- Deskripsi: Tabel untuk mencatat pertemuan kelompok kecil.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `group_meetings` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `group_id` BIGINT NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `agenda` TEXT NULL,
  `meeting_datetime` DATETIME NOT NULL,
  `location` VARCHAR(255) NULL,
  `attendees_count` INT NULL,
  `notes` TEXT NULL,
  `led_by` BIGINT NULL, -- Anggota yang memimpin pertemuan
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_group_meetings_small_groups_idx` (`group_id` ASC) VISIBLE,
  INDEX `fk_group_meetings_members_idx` (`led_by` ASC) VISIBLE,
  CONSTRAINT `fk_group_meetings_small_groups`
    FOREIGN KEY (`group_id`)
    REFERENCES `small_groups` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_group_meetings_members`
    FOREIGN KEY (`led_by`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `group_meeting_attendance`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `meeting_id` merujuk ke `group_meetings.id`, `member_id` merujuk ke `members.id`
-- Deskripsi: Tabel untuk mencatat kehadiran anggota di pertemuan kelompok kecil.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `group_meeting_attendance` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `meeting_id` BIGINT NOT NULL,
  `member_id` BIGINT NOT NULL,
  `attended` BOOLEAN NOT NULL DEFAULT 1,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `meeting_id_member_id_UNIQUE` (`meeting_id` ASC, `member_id` ASC) VISIBLE,
  INDEX `fk_group_meeting_attendance_group_meetings_idx` (`meeting_id` ASC) VISIBLE,
  INDEX `fk_group_meeting_attendance_members_idx` (`member_id` ASC) VISIBLE,
  CONSTRAINT `fk_group_meeting_attendance_group_meetings`
    FOREIGN KEY (`meeting_id`)
    REFERENCES `group_meetings` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_group_meeting_attendance_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ministries`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `leader_id` merujuk ke `members.id`
-- Deskripsi: Tabel untuk mengelola pelayanan (ministry) dalam gereja (misal: Pelayanan Anak, Pelayanan Musik).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `ministries` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `name` VARCHAR(255) NOT NULL,
  `ministry_type` VARCHAR(100) NULL, -- Contoh: 'Children', 'Worship', 'Outreach'
  `description` TEXT NULL,
  `leader_id` BIGINT NULL, -- Anggota yang menjadi pemimpin pelayanan
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `requirements` JSON NULL, -- Persyaratan untuk bergabung (misal: {'skills': ['singing', 'playing guitar']})
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_ministries_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_ministries_branches_idx` (`branch_id` ASC) VISIBLE,
  INDEX `fk_ministries_members_idx` (`leader_id` ASC) VISIBLE,
  CONSTRAINT `fk_ministries_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_ministries_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_ministries_members`
    FOREIGN KEY (`leader_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ministry_members`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `ministry_id` merujuk ke `ministries.id`, `member_id` merujuk ke `members.id`
-- Deskripsi: Tabel pivot untuk mengaitkan anggota dengan pelayanan yang mereka layani.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `ministry_members` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `ministry_id` BIGINT NOT NULL,
  `member_id` BIGINT NOT NULL,
  `role` VARCHAR(100) NULL, -- Peran dalam pelayanan (misal: 'Volunteer', 'Coordinator')
  `joined_date` DATE NOT NULL DEFAULT (CURRENT_DATE),
  `left_date` DATE NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `skills` JSON NULL, -- Keterampilan yang dimiliki anggota untuk pelayanan ini
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `ministry_id_member_id_UNIQUE` (`ministry_id` ASC, `member_id` ASC) VISIBLE,
  INDEX `fk_ministry_members_ministries_idx` (`ministry_id` ASC) VISIBLE,
  INDEX `fk_ministry_members_members_idx` (`member_id` ASC) VISIBLE,
  CONSTRAINT `fk_ministry_members_ministries`
    FOREIGN KEY (`ministry_id`)
    REFERENCES `ministries` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_ministry_members_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `service_schedules`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `service_id` merujuk ke `services.id`,
-- `ministry_id` merujuk ke `ministries.id`, `member_id` merujuk ke `members.id`
-- Deskripsi: Tabel untuk jadwal pelayanan (siapa yang melayani, peran apa, di kebaktian mana).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `service_schedules` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `service_id` BIGINT NOT NULL,
  `ministry_id` BIGINT NULL, -- Pelayanan yang dijadwalkan
  `member_id` BIGINT NULL, -- Anggota yang dijadwalkan
  `role` VARCHAR(100) NULL, -- Peran dalam jadwal (misal: 'Worship Leader', 'Usher')
  `scheduled_datetime` DATETIME NOT NULL,
  `status` ENUM('Scheduled', 'Confirmed', 'Completed', 'Cancelled') DEFAULT 'Scheduled' NOT NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_service_schedules_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_service_schedules_services_idx` (`service_id` ASC) VISIBLE,
  INDEX `fk_service_schedules_ministries_idx` (`ministry_id` ASC) VISIBLE,
  INDEX `fk_service_schedules_members_idx` (`member_id` ASC) VISIBLE,
  CONSTRAINT `fk_service_schedules_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_service_schedules_services`
    FOREIGN KEY (`service_id`)
    REFERENCES `services` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_service_schedules_ministries`
    FOREIGN KEY (`ministry_id`)
    REFERENCES `ministries` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_service_schedules_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `member_skills`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `member_id` merujuk ke `members.id`
-- Deskripsi: Tabel untuk mencatat keterampilan yang dimiliki oleh anggota (misal: musik, desain, mengajar).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `member_skills` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `member_id` BIGINT NOT NULL,
  `skill_name` VARCHAR(255) NOT NULL,
  `skill_category` VARCHAR(100) NULL, -- Contoh: 'Worship', 'Technical', 'Teaching'
  `proficiency_level` ENUM('Beginner', 'Intermediate', 'Advanced', 'Expert') NULL,
  `description` TEXT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `member_id_skill_name_UNIQUE` (`member_id` ASC, `skill_name` ASC) VISIBLE,
  INDEX `fk_member_skills_members_idx` (`member_id` ASC) VISIBLE,
  CONSTRAINT `fk_member_skills_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `visitations`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `member_id` merujuk ke `members.id`,
-- `visited_by` merujuk ke `members.id` (yang melakukan kunjungan, biasanya staf/pemimpin)
-- Deskripsi: Tabel untuk mencatat kunjungan pastoral atau kunjungan rumah.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `visitations` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `member_id` BIGINT NOT NULL, -- Anggota yang dikunjungi
  `visited_by` BIGINT NULL, -- Anggota atau staf yang melakukan kunjungan
  `visit_type` VARCHAR(100) NULL, -- Contoh: 'Hospital Visit', 'Home Visit', 'Follow-up'
  `visit_datetime` DATETIME NOT NULL,
  `location` VARCHAR(255) NULL,
  `purpose` TEXT NULL,
  `notes` TEXT NULL,
  `follow_up_actions` TEXT NULL,
  `status` ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled' NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_visitations_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_visitations_members_idx` (`member_id` ASC) VISIBLE,
  INDEX `fk_visitations_visited_by_idx` (`visited_by` ASC) VISIBLE,
  CONSTRAINT `fk_visitations_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_visitations_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_visitations_visited_by`
    FOREIGN KEY (`visited_by`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `counseling_sessions`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `member_id` merujuk ke `members.id`,
-- `counselor_id` merujuk ke `members.id` (konselor biasanya anggota/staf)
-- Deskripsi: Tabel untuk mencatat sesi konseling.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `counseling_sessions` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `member_id` BIGINT NOT NULL, -- Anggota yang dikonseling
  `counselor_id` BIGINT NULL, -- Anggota atau staf yang menjadi konselor
  `session_type` VARCHAR(100) NULL, -- Contoh: 'Marriage', 'Grief', 'Spiritual'
  `session_datetime` DATETIME NOT NULL,
  `notes` TEXT NULL,
  `action_items` TEXT NULL,
  `next_session` DATETIME NULL,
  `status` ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled' NOT NULL,
  `is_confidential` BOOLEAN NOT NULL DEFAULT 1, -- Apakah sesi ini bersifat rahasia
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_counseling_sessions_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_counseling_sessions_members_idx` (`member_id` ASC) VISIBLE,
  INDEX `fk_counseling_sessions_counselor_idx` (`counselor_id` ASC) VISIBLE,
  CONSTRAINT `fk_counseling_sessions_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_counseling_sessions_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_counseling_sessions_counselor`
    FOREIGN KEY (`counselor_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `prayer_requests`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `member_id` merujuk ke `members.id`
-- Deskripsi: Tabel untuk mengelola permintaan doa dari anggota.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `prayer_requests` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `member_id` BIGINT NULL, -- Anggota yang membuat permintaan doa (opsional, bisa anonim)
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL,
  `priority` ENUM('Low', 'Medium', 'High', 'Urgent') DEFAULT 'Medium' NOT NULL,
  `status` ENUM('Pending', 'Answered', 'Closed') DEFAULT 'Pending' NOT NULL,
  `is_public` BOOLEAN NOT NULL DEFAULT 0, -- Apakah permintaan doa bisa dilihat publik
  `is_anonymous` BOOLEAN NOT NULL DEFAULT 0, -- Apakah permintaan doa anonim
  `requested_date` DATE NOT NULL DEFAULT (CURRENT_DATE),
  `answered_date` DATE NULL,
  `answer_notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_prayer_requests_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_prayer_requests_members_idx` (`member_id` ASC) VISIBLE,
  CONSTRAINT `fk_prayer_requests_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_prayer_requests_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `care_groups`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `leader_id` merujuk ke `members.id`
-- Deskripsi: Tabel untuk mengelola kelompok peduli (care group).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `care_groups` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `leader_id` BIGINT NULL, -- Anggota yang menjadi pemimpin kelompok peduli
  `group_type` VARCHAR(100) NULL, -- Contoh: 'Support Group', 'Discipleship Group'
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_care_groups_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_care_groups_members_idx` (`leader_id` ASC) VISIBLE,
  CONSTRAINT `fk_care_groups_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_care_groups_members`
    FOREIGN KEY (`leader_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `care_group_members`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `care_group_id` merujuk ke `care_groups.id`, `member_id` merujuk ke `members.id`
-- Deskripsi: Tabel pivot untuk mengaitkan anggota dengan kelompok peduli.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `care_group_members` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `care_group_id` BIGINT NOT NULL,
  `member_id` BIGINT NOT NULL,
  `joined_date` DATE NOT NULL DEFAULT (CURRENT_DATE),
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `care_group_id_member_id_UNIQUE` (`care_group_id` ASC, `member_id` ASC) VISIBLE,
  INDEX `fk_care_group_members_care_groups_idx` (`care_group_id` ASC) VISIBLE,
  INDEX `fk_care_group_members_members_idx` (`member_id` ASC) VISIBLE,
  CONSTRAINT `fk_care_group_members_care_groups`
    FOREIGN KEY (`care_group_id`)
    REFERENCES `care_groups` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_care_group_members_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `document_categories`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `parent_id` merujuk ke `document_categories.id` (self-referencing)
-- Deskripsi: Tabel untuk mengelola kategori dokumen.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `document_categories` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `parent_id` BIGINT NULL, -- Untuk kategori bersarang
  `sort_order` INT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_name_UNIQUE` (`organization_id` ASC, `name` ASC) VISIBLE,
  INDEX `fk_document_categories_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_document_categories_parent_idx` (`parent_id` ASC) VISIBLE,
  CONSTRAINT `fk_document_categories_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_document_categories_parent`
    FOREIGN KEY (`parent_id`)
    REFERENCES `document_categories` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `documents`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `uploaded_by` merujuk ke `users.id`,
-- `document_category_id` merujuk ke `document_categories.id`
-- Deskripsi: Tabel untuk menyimpan metadata dokumen yang diunggah ke sistem.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `documents` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `document_category_id` BIGINT NULL, -- Kategori dokumen
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `document_type` VARCHAR(100) NULL, -- Contoh: 'Policy', 'Form', 'Report'
  `file_path` TEXT NOT NULL, -- Path atau URL ke file yang disimpan
  `file_name` VARCHAR(255) NOT NULL,
  `file_size` VARCHAR(50) NULL, -- Ukuran file (misal: '1.2 MB')
  `mime_type` VARCHAR(100) NULL, -- Tipe MIME file (misal: 'application/pdf')
  `access_level` VARCHAR(50) DEFAULT 'private' NOT NULL, -- Contoh: 'public', 'private', 'members_only'
  `uploaded_by` BIGINT NULL, -- User yang mengunggah dokumen
  `metadata` JSON NULL, -- Metadata tambahan dalam format JSON
  `version` INT DEFAULT 1 NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_documents_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_documents_users_idx` (`uploaded_by` ASC) VISIBLE,
  INDEX `fk_documents_document_categories_idx` (`document_category_id` ASC) VISIBLE,
  CONSTRAINT `fk_documents_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_documents_users`
    FOREIGN KEY (`uploaded_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_documents_document_categories`
    FOREIGN KEY (`document_category_id`)
    REFERENCES `document_categories` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `certificates`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `member_id` merujuk ke `members.id`,
-- `issued_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mencatat sertifikat yang dikeluarkan (misal: sertifikat baptisan, sertifikat partisipasi).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `certificates` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `member_id` BIGINT NOT NULL,
  `certificate_type` VARCHAR(100) NOT NULL, -- Contoh: 'Baptism', 'Completion', 'Recognition'
  `certificate_number` VARCHAR(255) NULL, -- Nomor sertifikat unik
  `issued_date` DATE NOT NULL DEFAULT (CURRENT_DATE),
  `details` TEXT NULL,
  `template_used` VARCHAR(255) NULL, -- Nama template sertifikat yang digunakan
  `file_path` TEXT NULL, -- Path atau URL ke file sertifikat yang dihasilkan
  `issued_by` BIGINT NULL, -- User yang mengeluarkan sertifikat
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_member_id_type_UNIQUE` (`organization_id` ASC, `member_id` ASC, `certificate_type` ASC) VISIBLE,
  INDEX `fk_certificates_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_certificates_members_idx` (`member_id` ASC) VISIBLE,
  INDEX `fk_certificates_users_idx` (`issued_by` ASC) VISIBLE,
  CONSTRAINT `fk_certificates_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_certificates_members`
    FOREIGN KEY (`member_id`)
    REFERENCES `members` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_certificates_users`
    FOREIGN KEY (`issued_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `sermons`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `preacher_id` merujuk ke `members.id`, `service_id` merujuk ke `services.id`
-- Deskripsi: Tabel untuk detail khotbah atau pesan.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `sermons` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `scripture_reference` VARCHAR(255) NULL, -- Contoh: 'John 3:16'
  `preacher_id` BIGINT NULL, -- Anggota yang menyampaikan khotbah
  `service_id` BIGINT NULL, -- Layanan gereja di mana khotbah disampaikan
  `sermon_date` DATE NOT NULL,
  `audio_url` TEXT NULL,
  `video_url` TEXT NULL,
  `transcript_url` TEXT NULL,
  `tags` JSON NULL, -- Tagging untuk kategori khotbah
  `download_count` INT DEFAULT 0 NOT NULL,
  `view_count` INT DEFAULT 0 NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_sermons_date` (`sermon_date` ASC) VISIBLE,
  INDEX `fk_sermons_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_sermons_branches_idx` (`branch_id` ASC) VISIBLE,
  INDEX `fk_sermons_members_idx` (`preacher_id` ASC) VISIBLE,
  INDEX `fk_sermons_services_idx` (`service_id` ASC) VISIBLE,
  CONSTRAINT `fk_sermons_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_sermons_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_sermons_members`
    FOREIGN KEY (`preacher_id`)
    REFERENCES `members` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_sermons_services`
    FOREIGN KEY (`service_id`)
    REFERENCES `services` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `facilities`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`
-- Deskripsi: Tabel untuk mengelola fasilitas gereja (misal: ruang pertemuan, aula).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `facilities` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `name` VARCHAR(255) NOT NULL,
  `facility_type` VARCHAR(100) NULL, -- Contoh: 'Meeting Room', 'Auditorium', 'Classroom'
  `description` TEXT NULL,
  `capacity` INT NULL,
  `location` VARCHAR(255) NULL, -- Lokasi fisik dalam cabang
  `amenities` JSON NULL, -- Fasilitas yang tersedia (misal: {'projector': true, 'wifi': true})
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_name_branch_id_UNIQUE` (`organization_id` ASC, `name` ASC, `branch_id` ASC) VISIBLE,
  INDEX `fk_facilities_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_facilities_branches_idx` (`branch_id` ASC) VISIBLE,
  CONSTRAINT `fk_facilities_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_facilities_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `facility_bookings`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `facility_id` merujuk ke `facilities.id`, `booked_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mencatat pemesanan fasilitas.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `facility_bookings` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `facility_id` BIGINT NOT NULL,
  `booked_by` BIGINT NOT NULL, -- User yang membuat pemesanan
  `booking_type` VARCHAR(100) NULL, -- Contoh: 'Personal', 'Ministry', 'Event'
  `purpose` TEXT NULL,
  `start_datetime` DATETIME NOT NULL,
  `end_datetime` DATETIME NOT NULL,
  `status` ENUM('Pending', 'Approved', 'Rejected', 'Cancelled', 'Completed') DEFAULT 'Pending' NOT NULL,
  `cost` DECIMAL(15,2) DEFAULT 0.00 NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_facility_bookings_datetime` (`start_datetime` ASC, `end_datetime` ASC) VISIBLE,
  INDEX `fk_facility_bookings_facilities_idx` (`facility_id` ASC) VISIBLE,
  INDEX `fk_facility_bookings_users_idx` (`booked_by` ASC) VISIBLE,
  CONSTRAINT `fk_facility_bookings_facilities`
    FOREIGN KEY (`facility_id`)
    REFERENCES `facilities` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_facility_bookings_users`
    FOREIGN KEY (`booked_by`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `equipment`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `branch_id` merujuk ke `branches.id`,
-- `assigned_to` merujuk ke `members.id` atau `facilities.id` (logis, tidak langsung FK)
-- Deskripsi: Tabel untuk mengelola inventaris peralatan.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `equipment` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `branch_id` BIGINT NULL,
  `name` VARCHAR(255) NOT NULL,
  `equipment_type` VARCHAR(100) NULL, -- Contoh: 'Sound System', 'Projector', 'Musical Instrument'
  `model` VARCHAR(255) NULL,
  `serial_number` VARCHAR(255) NULL,
  `purchase_date` DATE NULL,
  `purchase_price` DECIMAL(15,2) NULL,
  `equipment_condition` VARCHAR(100) NULL, -- Contoh: 'New', 'Used', 'Needs Repair'
  `location` VARCHAR(255) NULL, -- Lokasi fisik penyimpanan (misal: 'Sound Booth', 'Storage Room')
  `assigned_to` BIGINT NULL, -- Jika peralatan ditugaskan ke anggota atau fasilitas (logis)
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_equipment_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_equipment_branches_idx` (`branch_id` ASC) VISIBLE,
  CONSTRAINT `fk_equipment_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_equipment_branches`
    FOREIGN KEY (`branch_id`)
    REFERENCES `branches` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `maintenance_schedules`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `equipment_id` merujuk ke `equipment.id`
-- Deskripsi: Tabel untuk mencatat jadwal pemeliharaan peralatan.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `maintenance_schedules` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `equipment_id` BIGINT NOT NULL,
  `maintenance_type` VARCHAR(100) NULL, -- Contoh: 'Preventive', 'Repair', 'Calibration'
  `frequency` VARCHAR(100) NULL, -- Contoh: 'Monthly', 'Quarterly', 'Annually'
  `last_maintenance` DATE NULL,
  `next_maintenance` DATE NULL,
  `status` ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled' NOT NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_maintenance_schedules_equipment_idx` (`equipment_id` ASC) VISIBLE,
  CONSTRAINT `fk_maintenance_schedules_equipment`
    FOREIGN KEY (`equipment_id`)
    REFERENCES `equipment` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `reports`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `created_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mendefinisikan laporan yang dapat dihasilkan oleh sistem.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `reports` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `report_type` VARCHAR(100) NULL, -- Contoh: 'Financial', 'Attendance', 'Member Demographics'
  `description` TEXT NULL,
  `parameters` JSON NULL, -- Parameter yang dibutuhkan untuk menghasilkan laporan (misal: {'start_date': '2023-01-01'})
  `filters` JSON NULL, -- Filter yang dapat diterapkan pada laporan
  `output_format` VARCHAR(50) NULL, -- Contoh: 'PDF', 'CSV', 'Excel'
  `created_by` BIGINT NULL,
  `is_scheduled` BOOLEAN NOT NULL DEFAULT 0, -- Apakah laporan dijadwalkan
  `schedule_frequency` VARCHAR(100) NULL, -- Contoh: 'Daily', 'Weekly', 'Monthly'
  `last_run` DATETIME NULL,
  `next_run` DATETIME NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_name_UNIQUE` (`organization_id` ASC, `name` ASC) VISIBLE,
  INDEX `fk_reports_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_reports_users_idx` (`created_by` ASC) VISIBLE,
  CONSTRAINT `fk_reports_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_reports_users`
    FOREIGN KEY (`created_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `report_executions`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `report_id` merujuk ke `reports.id`, `executed_by` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mencatat setiap kali laporan dihasilkan (eksekusi laporan).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `report_executions` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `report_id` BIGINT NOT NULL,
  `executed_by` BIGINT NULL, -- User yang mengeksekusi laporan
  `execution_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` ENUM('Success', 'Failed', 'Processing') DEFAULT 'Processing' NOT NULL,
  `file_path` TEXT NULL, -- Path atau URL ke file laporan yang dihasilkan
  `error_message` TEXT NULL,
  `execution_stats` JSON NULL, -- Statistik eksekusi (misal: waktu yang dibutuhkan)
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_report_executions_reports_idx` (`report_id` ASC) VISIBLE,
  INDEX `fk_report_executions_users_idx` (`executed_by` ASC) VISIBLE,
  CONSTRAINT `fk_report_executions_reports`
    FOREIGN KEY (`report_id`)
    REFERENCES `reports` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_report_executions_users`
    FOREIGN KEY (`executed_by`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mobile_devices`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `user_id` merujuk ke `users.id`
-- Deskripsi: Tabel untuk menyimpan informasi perangkat seluler yang terdaftar untuk notifikasi push.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mobile_devices` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `device_token` VARCHAR(255) NOT NULL, -- Token untuk push notification (FCM, APN)
  `platform` VARCHAR(50) NULL, -- Contoh: 'Android', 'iOS'
  `device_info` VARCHAR(255) NULL, -- Informasi perangkat (model, OS version)
  `is_active` BOOLEAN NOT NULL DEFAULT 1,
  `last_used` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `device_token_UNIQUE` (`device_token` ASC) VISIBLE,
  INDEX `fk_mobile_devices_users_idx` (`user_id` ASC) VISIBLE,
  CONSTRAINT `fk_mobile_devices_users`
    FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `push_notifications`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel untuk mengelola dan melacak pengiriman notifikasi push.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `push_notifications` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `message` TEXT NOT NULL,
  `notification_type` VARCHAR(100) NULL, -- Contoh: 'Announcement', 'Event Reminder', 'Personal'
  `target_users` JSON NULL, -- Daftar user_id atau member_id yang ditargetkan
  `target_criteria` JSON NULL, -- Kriteria penargetan (misal: {'member_category': 'Youth'})
  `scheduled_at` DATETIME NULL,
  `sent_at` DATETIME NULL,
  `status` ENUM('Pending', 'Sent', 'Failed', 'Scheduled') DEFAULT 'Pending' NOT NULL,
  `delivery_stats` JSON NULL, -- Statistik pengiriman (misal: 'delivered', 'opened')
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_push_notifications_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_push_notifications_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `integrations`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel untuk mengelola konfigurasi integrasi dengan sistem eksternal (misal: Mailchimp, payment gateways).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `integrations` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `integration_type` VARCHAR(100) NOT NULL, -- Contoh: 'Email Marketing', 'Payment Gateway', 'SMS Gateway'
  `provider` VARCHAR(100) NOT NULL, -- Contoh: 'Mailchimp', 'Stripe', 'Twilio'
  `configuration` JSON NULL, -- Detail konfigurasi (misal: API endpoint)
  `credentials` JSON NULL, -- Kredensial API (harus dienkripsi dalam aplikasi)
  `is_active` BOOLEAN NOT NULL DEFAULT 0,
  `last_sync` DATETIME NULL,
  `status` ENUM('Active', 'Inactive', 'Error') DEFAULT 'Inactive' NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_type_provider_UNIQUE` (`organization_id` ASC, `integration_type` ASC, `provider` ASC) VISIBLE,
  INDEX `fk_integrations_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_integrations_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `api_keys`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel untuk mengelola API keys yang dapat digunakan oleh aplikasi pihak ketiga atau internal.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `api_keys` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `api_key` VARCHAR(255) NOT NULL, -- Kunci API (harus dienkripsi)
  `api_secret` VARCHAR(255) NULL, -- API secret (harus dienkripsi)
  `permissions` JSON NULL, -- Izin yang terkait dengan kunci API ini
  `is_active` BOOLEAN NOT NULL DEFAULT 0,
  `expires_at` DATETIME NULL,
  `usage_count` INT DEFAULT 0 NOT NULL,
  `rate_limit` INT NULL, -- Batas rate limit untuk kunci ini
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `api_key_UNIQUE` (`api_key` ASC) VISIBLE,
  INDEX `fk_api_keys_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_api_keys_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `audit_logs`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`, `user_id` merujuk ke `users.id`
-- Deskripsi: Tabel untuk mencatat semua aktivitas penting dalam sistem demi audit dan keamanan.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `audit_logs` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `user_id` BIGINT NULL, -- User yang melakukan tindakan
  `action` VARCHAR(255) NOT NULL, -- Deskripsi tindakan (misal: 'User Created', 'Member Updated')
  `module` VARCHAR(100) NULL, -- Modul tempat tindakan terjadi (misal: 'Users', 'Members')
  `record_type` VARCHAR(100) NULL, -- Tipe record yang terpengaruh (misal: 'User', 'Member')
  `record_id` BIGINT NULL, -- ID record yang terpengaruh
  `old_values` JSON NULL, -- Nilai lama sebelum perubahan (JSON)
  `new_values` JSON NULL, -- Nilai baru setelah perubahan (JSON)
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_audit_logs_created_at` (`created_at` ASC) VISIBLE,
  INDEX `fk_audit_logs_organizations_idx` (`organization_id` ASC) VISIBLE,
  INDEX `fk_audit_logs_users_idx` (`user_id` ASC) VISIBLE,
  CONSTRAINT `fk_audit_logs_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_audit_logs_users`
    FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `system_settings`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel untuk menyimpan pengaturan sistem yang dapat dikonfigurasi per organisasi.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `system_settings` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `setting_key` VARCHAR(255) NOT NULL, -- Kunci pengaturan (misal: 'email_notification_enabled')
  `setting_value` TEXT NULL, -- Nilai pengaturan
  `data_type` VARCHAR(50) NULL, -- Tipe data nilai (misal: 'boolean', 'string', 'json')
  `description` TEXT NULL,
  `is_encrypted` BOOLEAN NOT NULL DEFAULT 0, -- Apakah nilai pengaturan dienkripsi
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `organization_id_setting_key_UNIQUE` (`organization_id` ASC, `setting_key` ASC) VISIBLE,
  INDEX `fk_system_settings_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_system_settings_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `backups`
-- Kunci utama: `id` (BIGINT)
-- Kunci asing: `organization_id` merujuk ke `organizations.id`
-- Deskripsi: Tabel untuk mencatat informasi backup sistem atau data.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `backups` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `organization_id` BIGINT NOT NULL,
  `backup_type` VARCHAR(100) NULL, -- Contoh: 'Full', 'Incremental', 'Database Only'
  `file_path` TEXT NULL, -- Path atau URL ke file backup
  `file_size` VARCHAR(50) NULL, -- Ukuran file backup
  `status` ENUM('Success', 'Failed', 'Processing') DEFAULT 'Processing' NOT NULL,
  `backup_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` DATETIME NULL, -- Tanggal kedaluwarsa backup
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_backups_organizations_idx` (`organization_id` ASC) VISIBLE,
  CONSTRAINT `fk_backups_organizations`
    FOREIGN KEY (`organization_id`)
    REFERENCES `organizations` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Table `password_reset_tokens`
-- Deskripsi: Tabel untuk menyimpan token reset password yang dihasilkan
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `password_reset_tokens` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `token` VARCHAR(255) NOT NULL UNIQUE,
  `expiry_date` DATETIME NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_password_reset_tokens_users_idx` (`user_id` ASC) VISIBLE,
  CONSTRAINT `fk_password_reset_tokens_users`
    FOREIGN KEY (`user_id`)
    REFERENCES `users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
)
ENGINE = InnoDB;

