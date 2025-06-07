# Church Management System - Entity Relationship Diagram

## Deskripsi
ERD lengkap untuk Church Management System SaaS yang mencakup semua modul dari Fase 1-10 implementasi.

## Mermaid ERD Code

```mermaid
erDiagram
    %% CORE SYSTEM TABLES
    organizations {
        bigint id PK
        string name
        string email
        string phone
        text address
        string city
        string state
        string country
        string postal_code
        string timezone
        string currency
        string language
        string status
        text logo_url
        json branding_config
        json system_preferences
        timestamp created_at
        timestamp updated_at
    }

    branches {
        bigint id PK
        bigint organization_id FK
        string name
        string code
        text address
        string city
        string phone
        string email
        boolean is_main
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    %% AUTHENTICATION & AUTHORIZATION
    users {
        bigint id PK
        bigint organization_id FK
        string email
        string username
        string password_hash
        string first_name
        string last_name
        string phone
        string avatar_url
        boolean email_verified
        boolean is_active
        boolean require_2fa
        timestamp last_login_at
        timestamp created_at
        timestamp updated_at
    }

    roles {
        bigint id PK
        bigint organization_id FK
        string name
        string slug
        text description
        boolean is_system_role
        timestamp created_at
        timestamp updated_at
    }

    permissions {
        bigint id PK
        string name
        string slug
        string module
        text description
        timestamp created_at
        timestamp updated_at
    }

    user_roles {
        bigint id PK
        bigint user_id FK
        bigint role_id FK
        timestamp assigned_at
    }

    role_permissions {
        bigint id PK
        bigint role_id FK
        bigint permission_id FK
        timestamp created_at
    }

    user_sessions {
        bigint id PK
        bigint user_id FK
        string session_token
        string ip_address
        string user_agent
        timestamp expires_at
        timestamp created_at
    }

    %% MEMBER MANAGEMENT
    members {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        bigint user_id FK
        string member_number
        string first_name
        string last_name
        string middle_name
        string nickname
        string gender
        date date_of_birth
        string phone
        string email
        text address
        string city
        string state
        string postal_code
        string marital_status
        string occupation
        string education
        string photo_url
        string membership_status
        string member_category
        date joined_date
        date baptism_date
        date confirmation_date
        bigint family_id FK
        boolean is_family_head
        json emergency_contacts
        json custom_fields
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    families {
        bigint id PK
        bigint organization_id FK
        string family_name
        string family_code
        bigint head_member_id FK
        text address
        string phone
        string email
        json custom_fields
        timestamp created_at
        timestamp updated_at
    }

    member_relationships {
        bigint id PK
        bigint member_id FK
        bigint related_member_id FK
        string relationship_type
        timestamp created_at
    }

    %% COMMUNICATION
    announcements {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        bigint created_by FK
        string title
        text content
        string priority
        string status
        date publish_date
        date expire_date
        json target_audience
        boolean send_notification
        timestamp created_at
        timestamp updated_at
    }

    communication_templates {
        bigint id PK
        bigint organization_id FK
        string name
        string type
        string subject
        text content
        json variables
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    communications {
        bigint id PK
        bigint organization_id FK
        bigint template_id FK
        bigint sent_by FK
        string type
        string subject
        text content
        json recipients
        string status
        datetime sent_at
        json delivery_stats
        timestamp created_at
        timestamp updated_at
    }

    %% FINANCIAL MANAGEMENT
    offerings {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        bigint member_id FK
        string offering_type
        decimal amount
        string currency
        date offering_date
        string payment_method
        string reference_number
        text notes
        bigint recorded_by FK
        timestamp created_at
        timestamp updated_at
    }

    donations {
        bigint id PK
        bigint organization_id FK
        bigint member_id FK
        bigint project_id FK
        string donation_type
        decimal amount
        string currency
        date donation_date
        string payment_method
        string reference_number
        string status
        text notes
        boolean is_anonymous
        timestamp created_at
        timestamp updated_at
    }

    donation_projects {
        bigint id PK
        bigint organization_id FK
        string name
        text description
        decimal target_amount
        decimal current_amount
        date start_date
        date end_date
        string status
        string image_url
        timestamp created_at
        timestamp updated_at
    }

    pledges {
        bigint id PK
        bigint organization_id FK
        bigint member_id FK
        bigint project_id FK
        decimal pledge_amount
        decimal paid_amount
        date pledge_date
        date due_date
        string frequency
        string status
        text notes
        timestamp created_at
        timestamp updated_at
    }

    budgets {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        string name
        int year
        decimal total_amount
        string status
        timestamp created_at
        timestamp updated_at
    }

    budget_categories {
        bigint id PK
        bigint budget_id FK
        string name
        decimal allocated_amount
        decimal spent_amount
        text description
        timestamp created_at
        timestamp updated_at
    }

    expenses {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        bigint category_id FK
        string description
        decimal amount
        string currency
        date expense_date
        string payment_method
        string reference_number
        string receipt_url
        bigint approved_by FK
        string status
        timestamp created_at
        timestamp updated_at
    }

    %% EVENT MANAGEMENT
    events {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        string name
        text description
        string event_type
        datetime start_datetime
        datetime end_datetime
        string location
        int capacity
        int registered_count
        boolean requires_registration
        decimal registration_fee
        string status
        string image_url
        bigint created_by FK
        json custom_fields
        timestamp created_at
        timestamp updated_at
    }

    event_registrations {
        bigint id PK
        bigint event_id FK
        bigint member_id FK
        string guest_name
        string guest_email
        string guest_phone
        string status
        datetime registered_at
        decimal fee_paid
        string payment_status
        text notes
        json custom_responses
        timestamp created_at
        timestamp updated_at
    }

    event_attendance {
        bigint id PK
        bigint event_id FK
        bigint member_id FK
        datetime check_in_time
        datetime check_out_time
        string check_in_method
        bigint checked_in_by FK
        text notes
        timestamp created_at
    }

event_types {
        bigint id PK
        bigint organization_id FK
        string name
        text description
        boolean is_active
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }

    configurable_statuses {
        bigint id PK
        bigint organization_id FK
        string entity_type
        string status_name
        string status_code
        text description
        boolean is_active
        int sort_order
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }

    %% ATTENDANCE TRACKING
    services {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        string name
        string service_type
        datetime service_datetime
        string location
        int expected_attendance
        int actual_attendance
        string status
        bigint led_by FK
        text notes
        timestamp created_at
        timestamp updated_at
    }

    service_attendance {
        bigint id PK
        bigint service_id FK
        bigint member_id FK
        datetime check_in_time
        string check_in_method
        bigint checked_in_by FK
        text notes
        timestamp created_at
    }

    %% SMALL GROUPS
    small_groups {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        string name
        string group_type
        text description
        bigint leader_id FK
        bigint co_leader_id FK
        string meeting_schedule
        string meeting_location
        int max_members
        int current_members
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    group_members {
        bigint id PK
        bigint group_id FK
        bigint member_id FK
        string role
        date joined_date
        date left_date
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    group_meetings {
        bigint id PK
        bigint group_id FK
        string title
        text agenda
        datetime meeting_datetime
        string location
        int attendees_count
        text notes
        bigint led_by FK
        timestamp created_at
        timestamp updated_at
    }

    group_meeting_attendance {
        bigint id PK
        bigint meeting_id FK
        bigint member_id FK
        boolean attended
        text notes
        timestamp created_at
    }

    %% MINISTRY MANAGEMENT
    ministries {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        string name
        string ministry_type
        text description
        bigint leader_id FK
        boolean is_active
        json requirements
        timestamp created_at
        timestamp updated_at
    }

    ministry_members {
        bigint id PK
        bigint ministry_id FK
        bigint member_id FK
        string role
        date joined_date
        date left_date
        boolean is_active
        json skills
        timestamp created_at
        timestamp updated_at
    }

    service_schedules {
        bigint id PK
        bigint organization_id FK
        bigint service_id FK
        bigint ministry_id FK
        bigint member_id FK
        string role
        datetime scheduled_datetime
        string status
        text notes
        timestamp created_at
        timestamp updated_at
    }

    member_skills {
        bigint id PK
        bigint member_id FK
        string skill_name
        string skill_category
        string proficiency_level
        text description
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    %% PASTORAL CARE
    visitations {
        bigint id PK
        bigint organization_id FK
        bigint member_id FK
        bigint visited_by FK
        string visit_type
        datetime visit_datetime
        string location
        text purpose
        text notes
        text follow_up_actions
        string status
        timestamp created_at
        timestamp updated_at
    }

    counseling_sessions {
        bigint id PK
        bigint organization_id FK
        bigint member_id FK
        bigint counselor_id FK
        string session_type
        datetime session_datetime
        text notes
        text action_items
        datetime next_session
        string status
        boolean is_confidential
        timestamp created_at
        timestamp updated_at
    }

    prayer_requests {
        bigint id PK
        bigint organization_id FK
        bigint member_id FK
        string title
        text description
        string priority
        string status
        boolean is_public
        boolean is_anonymous
        date requested_date
        date answered_date
        text answer_notes
        timestamp created_at
        timestamp updated_at
    }

    care_groups {
        bigint id PK
        bigint organization_id FK
        string name
        text description
        bigint leader_id FK
        string group_type
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    care_group_members {
        bigint id PK
        bigint care_group_id FK
        bigint member_id FK
        date joined_date
        boolean is_active
        timestamp created_at
    }

    %% DOCUMENT MANAGEMENT
    documents {
        bigint id PK
        bigint organization_id FK
        string title
        text description
        string document_type
        string file_path
        string file_name
        string file_size
        string mime_type
        string access_level
        bigint uploaded_by FK
        json metadata
        int version
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    document_categories {
        bigint id PK
        bigint organization_id FK
        string name
        text description
        bigint parent_id FK
        int sort_order
        timestamp created_at
        timestamp updated_at
    }

    certificates {
        bigint id PK
        bigint organization_id FK
        bigint member_id FK
        string certificate_type
        string certificate_number
        date issued_date
        text details
        string template_used
        string file_path
        bigint issued_by FK
        timestamp created_at
        timestamp updated_at
    }

    sermons {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        string title
        text description
        string scripture_reference
        bigint preacher_id FK
        bigint service_id FK
        date sermon_date
        string audio_url
        string video_url
        string transcript_url
        json tags
        int download_count
        int view_count
        timestamp created_at
        timestamp updated_at
    }

    %% FACILITY MANAGEMENT
    facilities {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        string name
        string facility_type
        text description
        int capacity
        text location
        json amenities
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    facility_bookings {
        bigint id PK
        bigint facility_id FK
        bigint booked_by FK
        string booking_type
        string purpose
        datetime start_datetime
        datetime end_datetime
        string status
        decimal cost
        text notes
        timestamp created_at
        timestamp updated_at
    }

    equipment {
        bigint id PK
        bigint organization_id FK
        bigint branch_id FK
        string name
        string equipment_type
        string model
        string serial_number
        date purchase_date
        decimal purchase_price
        string equipment_condition
        text location
        bigint assigned_to FK
        timestamp created_at
        timestamp updated_at
    }

    maintenance_schedules {
        bigint id PK
        bigint equipment_id FK
        string maintenance_type
        string frequency
        date last_maintenance
        date next_maintenance
        string status
        text notes
        timestamp created_at
        timestamp updated_at
    }

    %% REPORTING & ANALYTICS
    reports {
        bigint id PK
        bigint organization_id FK
        string name
        string report_type
        text description
        json parameters
        json filters
        string output_format
        bigint created_by FK
        boolean is_scheduled
        string schedule_frequency
        datetime last_run
        datetime next_run
        timestamp created_at
        timestamp updated_at
    }

    report_executions {
        bigint id PK
        bigint report_id FK
        bigint executed_by FK
        datetime execution_time
        string status
        string file_path
        text error_message
        json execution_stats
        timestamp created_at
    }

    %% MOBILE & DIGITAL
    mobile_devices {
        bigint id PK
        bigint user_id FK
        string device_token
        string platform
        string device_info
        boolean is_active
        timestamp last_used
        timestamp created_at
        timestamp updated_at
    }

    push_notifications {
        bigint id PK
        bigint organization_id FK
        string title
        text message
        string notification_type
        json target_users
        json target_criteria
        datetime scheduled_at
        datetime sent_at
        string status
        json delivery_stats
        timestamp created_at
        timestamp updated_at
    }

    %% INTEGRATIONS
    integrations {
        bigint id PK
        bigint organization_id FK
        string integration_type
        string provider
        json configuration
        json credentials
        boolean is_active
        datetime last_sync
        string status
        timestamp created_at
        timestamp updated_at
    }

    api_keys {
        bigint id PK
        bigint organization_id FK
        string name
        string api_key
        string api_secret
        json permissions
        boolean is_active
        datetime expires_at
        int usage_count
        int rate_limit
        timestamp created_at
        timestamp updated_at
    }

    %% SYSTEM ADMINISTRATION
    audit_logs {
        bigint id PK
        bigint organization_id FK
        bigint user_id FK
        string action
        string module
        string record_type
        bigint record_id
        json old_values
        json new_values
        string ip_address
        string user_agent
        timestamp created_at
    }

    system_settings {
        bigint id PK
        bigint organization_id FK
        string setting_key
        text setting_value
        string data_type
        text description
        boolean is_encrypted
        timestamp updated_at
    }

    backups {
        bigint id PK
        bigint organization_id FK
        string backup_type
        string file_path
        string file_size
        string status
        datetime backup_datetime
        datetime expires_at
        text notes
        timestamp created_at
    }
    
    password_reset_tokens {
        bigint id PK
        bigint user_id FK
        varchar token
        timestamp expires_at
        boolean is_used
        timestamp created_at
    }


   %% RELATIONS
    organizations ||--o{ branches : "has"
    organizations ||--o{ users : "manages"
    organizations ||--o{ roles : "defines"
    organizations ||--o{ members : "has"
    organizations ||--o{ families : "oversees"
    organizations ||--o{ announcements : "publishes"
    organizations ||--o{ communication_templates : "uses"
    organizations ||--o{ communications : "sends"
    organizations ||--o{ events : "hosts"
    organizations ||--o{ event_types : "defines"
    organizations ||--o{ configurable_statuses : "configures"
    organizations ||--o{ services : "provides"
    organizations ||--o{ small_groups : "organizes"
    organizations ||--o{ ministries : "oversees"
    organizations ||--o{ offerings : "receives"
    organizations ||--o{ donations : "collects"
    organizations ||--o{ donation_projects : "runs"
    organizations ||--o{ pledges : "manages"
    organizations ||--o{ expenses : "tracks"
    organizations ||--o{ budgets : "manages"
    organizations ||--o{ facilities : "owns"
    organizations ||--o{ reports : "generates"
    organizations ||--o{ audit_logs : "records"
    organizations ||--o{ documents : "stores"
    organizations ||--o{ document_categories : "defines"

    branches ||--o{ members : "resides_in"
    branches ||--o{ families : "belongs_to"
    branches ||--o{ events : "occurs_at"
    branches ||--o{ services : "holds"
    branches ||--o{ small_groups : "hosts"
    branches ||--o{ offerings : "received_at"
    branches ||--o{ donations : "received_at"
    branches ||--o{ expenses : "incurred_at"
    branches ||--o{ budgets : "applies_to"
    branches ||--o{ facilities : "located_in"

    users ||--o{ user_roles : "has"
    users ||--o{ announcements : "creates"
    users ||--o{ communications : "initiates"
    users ||--o{ report_executions : "requests"
    users ||--o{ audit_logs : "performs"
    users ||--o{ facility_bookings : "makes"
    users ||--o{ documents : "uploads"

    roles ||--o{ user_roles : "assigned_to"
    roles ||--o{ role_permissions : "grants"
    permissions ||--o{ role_permissions : "given_by"

    members ||--o{ member_skills : "has"
    members ||--o{ event_registrations : "participates_in"
    members ||--o{ event_attendance : "attends"
    members ||--o{ service_attendance : "attends"
    members ||--o{ sermons : "speaker_is"
    members ||--o{ small_groups : "leader_is"
    members ||--o{ group_members : "belongs_to"
    members ||--o{ group_meeting_attendance : "attends"
    members ||--o{ ministries : "leader_is"
    members ||--o{ ministry_members : "serves_in"
    members ||--o{ offerings : "gives"
    members ||--o{ donations : "contributes"
    members ||--o{ pledges : "commits"
    members ||--o{ families : "belongs_to"

    families ||--o{ members : "includes"

    events ||--o{ event_registrations : "has"
    events ||--o{ event_attendance : "tracks"
    events ||--o{ event_types : "is_of_type"
    events ||--o{ configurable_statuses : "has_status"

    services ||--o{ service_attendance : "tracks"
    services ||--o{ service_schedules : "has"
    services ||--o{ sermons : "includes"

    small_groups ||--o{ group_members : "has"
    small_groups ||--o{ group_meetings : "conducts"

    group_meetings ||--o{ group_meeting_attendance : "tracks"

    ministries ||--o{ ministry_members : "has"
    ministries ||--o{ service_schedules : "provides"

    donation_projects ||--o{ donations : "receives"
    donation_projects ||--o{ pledges : "has"

    budgets ||--o{ budget_categories : "has"
    budget_categories ||--o{ expenses : "tracks"

    facilities ||--o{ facility_bookings : "has"

    reports ||--o{ report_executions : "generates"

    documents ||--o{ document_categories : "categorized_in"

    %% SPECIAL REFERENCES (Not direct FK but logical relations)
    sermons }o--|| members : speaker_id
    small_groups }o--|| members : leader_id
    ministries }o--|| members : leader_id
    documents }o--|| users : uploaded_by_user_id
```

