-- =============================================================================
-- DisasterLink — Initial Schema Migration
-- File: supabase/migrations/001_initial_schema.sql
-- Course: CS220 Database Design and Implementation | NUST SEECS | Spring 2026
-- =============================================================================
-- TABLE CREATION ORDER (dependency hierarchy):
--   1.  disaster_type
--   2.  disaster
--   3.  disaster_location
--   4.  relief_camp
--   5.  relief_program
--   6.  product
--   7.  resource_requirement
--   8.  org_category
--   9.  organization
--   10. program_enrollment
--   11. commitment
--   12. fulfillment
--   13. field_team
--   14. incident_report
--   15. beneficiary
--   16. aid_distribution
--   17. audit_log
-- =============================================================================


-- =============================================================================
-- SECTION 0 — ENUM TYPE DEFINITIONS
-- All ENUMs declared first so tables can reference them cleanly
-- =============================================================================

CREATE TYPE disaster_severity  AS ENUM ('Low', 'Medium', 'High', 'Critical');
CREATE TYPE disaster_status    AS ENUM ('Active', 'Closed');
CREATE TYPE location_status    AS ENUM ('Active', 'Cleared');
CREATE TYPE program_status     AS ENUM ('Planning', 'Active', 'Closed');
CREATE TYPE fulfillment_status AS ENUM ('Unfulfilled', 'Partial', 'Fulfilled');
CREATE TYPE priority_level     AS ENUM ('Low', 'Medium', 'High', 'Critical');
CREATE TYPE product_category   AS ENUM ('Food', 'Medicine', 'Shelter', 'Water', 'Equipment', 'Other');
CREATE TYPE approval_status    AS ENUM ('Pending', 'Approved', 'Rejected', 'Suspended');
CREATE TYPE enrollment_status  AS ENUM ('Active', 'Withdrawn');
CREATE TYPE commitment_status  AS ENUM ('Active', 'Cancelled', 'Fulfilled');
CREATE TYPE delivery_method    AS ENUM ('Direct', 'Warehouse', 'Camp');
CREATE TYPE team_status        AS ENUM ('Active', 'Withdrawn');
CREATE TYPE severity_flag      AS ENUM ('Info', 'Warning', 'Critical');
CREATE TYPE displacement_status AS ENUM ('Displaced', 'In-Place', 'Returned');
CREATE TYPE audit_action       AS ENUM ('INSERT', 'UPDATE', 'DELETE');
CREATE TYPE government_tier    AS ENUM ('Federal', 'Provincial', 'District');


-- =============================================================================
-- TABLE 1 — disaster_type
-- Lookup table: Flood, Earthquake, Drought, etc.
-- No foreign keys — safe to create first
-- =============================================================================

CREATE TABLE disaster_type (
    disaster_type_id  SERIAL          PRIMARY KEY,
    type_name         VARCHAR(100)    NOT NULL UNIQUE,
    description       TEXT
);

COMMENT ON TABLE  disaster_type            IS 'Lookup table for disaster categories (Flood, Earthquake, Drought, etc.)';
COMMENT ON COLUMN disaster_type.type_name  IS 'Unique human-readable name for the disaster type';


-- =============================================================================
-- TABLE 2 — disaster
-- Core entity. References disaster_type.
-- EER: severity_level uses disaster_severity ENUM
-- Trigger T2 fires AFTER UPDATE of severity_level → writes to audit_log
-- =============================================================================

CREATE TABLE disaster (
    disaster_id        SERIAL              PRIMARY KEY,
    disaster_type_id   INT                 NOT NULL
                           REFERENCES disaster_type(disaster_type_id)
                           ON DELETE RESTRICT,
    disaster_name      VARCHAR(200)        NOT NULL,
    severity_level     disaster_severity   NOT NULL DEFAULT 'Medium',
    declaration_date   DATE                NOT NULL,
    projected_end_date DATE,
    status             disaster_status     NOT NULL DEFAULT 'Active',
    description        TEXT,

    CONSTRAINT chk_disaster_dates
        CHECK (projected_end_date IS NULL OR projected_end_date >= declaration_date)
);

COMMENT ON TABLE  disaster                   IS 'A declared disaster event (flood, earthquake, etc.)';
COMMENT ON COLUMN disaster.severity_level    IS 'Low/Medium/High/Critical — changes are audit-logged by Trigger T2';
COMMENT ON COLUMN disaster.declaration_date  IS 'Official date the disaster was declared';


-- =============================================================================
-- TABLE 3 — disaster_location
-- Each disaster has one or more affected locations (district/tehsil level)
-- Composite address stored as separate columns (province, district, tehsil)
-- =============================================================================

CREATE TABLE disaster_location (
    location_id          SERIAL           PRIMARY KEY,
    disaster_id          INT              NOT NULL
                             REFERENCES disaster(disaster_id)
                             ON DELETE CASCADE,
    province             VARCHAR(100)     NOT NULL,
    district             VARCHAR(100)     NOT NULL,
    tehsil               VARCHAR(100),
    affected_population  INT              NOT NULL DEFAULT 0,
    gps_latitude         NUMERIC(9, 6),
    gps_longitude        NUMERIC(9, 6),
    location_status      location_status  NOT NULL DEFAULT 'Active',

    CONSTRAINT chk_population        CHECK (affected_population >= 0),
    CONSTRAINT chk_gps_latitude      CHECK (gps_latitude  IS NULL OR (gps_latitude  BETWEEN -90  AND 90)),
    CONSTRAINT chk_gps_longitude     CHECK (gps_longitude IS NULL OR (gps_longitude BETWEEN -180 AND 180))
);

COMMENT ON TABLE  disaster_location                    IS 'A district/tehsil-level geographic area affected by a disaster';
COMMENT ON COLUMN disaster_location.affected_population IS 'Estimated number of people affected in this location';
COMMENT ON COLUMN disaster_location.gps_latitude        IS 'Center-point latitude for mapping purposes';


-- =============================================================================
-- TABLE 4 — relief_camp
-- Resolves the MULTI-VALUED attribute on disaster_location
-- A single location can have multiple relief camps (EER extension)
-- =============================================================================

CREATE TABLE relief_camp (
    camp_id      SERIAL        PRIMARY KEY,
    location_id  INT           NOT NULL
                     REFERENCES disaster_location(location_id)
                     ON DELETE CASCADE,
    camp_name    VARCHAR(200)  NOT NULL,
    capacity     INT           NOT NULL DEFAULT 0,
    is_active    BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_capacity CHECK (capacity >= 0),
    CONSTRAINT uq_camp_name_per_location UNIQUE (location_id, camp_name)
);

COMMENT ON TABLE relief_camp IS 'Relief camps within a disaster location — resolves multi-valued camp attribute from EER model';


-- =============================================================================
-- TABLE 5 — relief_program
-- A coordination program launched for a specific disaster
-- created_by_admin_id references organization (set after TABLE 9)
-- =============================================================================

CREATE TABLE relief_program (
    program_id           SERIAL           PRIMARY KEY,
    disaster_id          INT              NOT NULL
                             REFERENCES disaster(disaster_id)
                             ON DELETE RESTRICT,
    program_name         VARCHAR(200)     NOT NULL,
    objectives           TEXT,
    start_date           DATE             NOT NULL,
    end_date             DATE,
    status               program_status   NOT NULL DEFAULT 'Planning',
    created_by_admin_id  INT,             -- FK added after organization table is created

    CONSTRAINT chk_program_dates
        CHECK (end_date IS NULL OR end_date >= start_date)
);

COMMENT ON TABLE  relief_program                     IS 'A structured relief effort linked to a declared disaster';
COMMENT ON COLUMN relief_program.created_by_admin_id IS 'FK to organization.org_id — the admin/authority that created this program';


-- =============================================================================
-- TABLE 6 — product
-- Master resource catalog: food packs, medicine kits, tarpaulins, etc.
-- =============================================================================

CREATE TABLE product (
    product_id      SERIAL            PRIMARY KEY,
    product_name    VARCHAR(200)      NOT NULL UNIQUE,
    category        product_category  NOT NULL,
    unit_of_measure VARCHAR(50)       NOT NULL,   -- e.g. 'kg', 'units', 'litres'
    description     TEXT
);

COMMENT ON TABLE  product                IS 'Master catalog of relief resources (food, medicine, shelter items, etc.)';
COMMENT ON COLUMN product.unit_of_measure IS 'The unit used to count this product (kg, units, boxes, litres, etc.)';


-- =============================================================================
-- TABLE 7 — resource_requirement
-- Specifies what products are needed, where, for which program
-- UNIQUE on (program_id, location_id, product_id) — no duplicate requirements
-- quantity_committed and quantity_fulfilled are maintained by Trigger T1
-- fulfillment_percentage is DERIVED — never stored, computed in views/SPs
-- =============================================================================

CREATE TABLE resource_requirement (
    requirement_id       SERIAL              PRIMARY KEY,
    program_id           INT                 NOT NULL
                             REFERENCES relief_program(program_id)
                             ON DELETE CASCADE,
    location_id          INT                 NOT NULL
                             REFERENCES disaster_location(location_id)
                             ON DELETE RESTRICT,
    product_id           INT                 NOT NULL
                             REFERENCES product(product_id)
                             ON DELETE RESTRICT,
    quantity_required    INT                 NOT NULL,
    quantity_committed   INT                 NOT NULL DEFAULT 0,  -- maintained by Trigger T1
    quantity_fulfilled   INT                 NOT NULL DEFAULT 0,  -- maintained by Trigger T1
    fulfillment_status   fulfillment_status  NOT NULL DEFAULT 'Unfulfilled',
    priority             priority_level      NOT NULL DEFAULT 'Medium',

    CONSTRAINT uq_requirement UNIQUE (program_id, location_id, product_id),
    CONSTRAINT chk_qty_required    CHECK (quantity_required  > 0),
    CONSTRAINT chk_qty_committed   CHECK (quantity_committed >= 0),
    CONSTRAINT chk_qty_fulfilled   CHECK (quantity_fulfilled >= 0),
    CONSTRAINT chk_fulfilled_lte_committed
        CHECK (quantity_fulfilled <= quantity_committed)
);

COMMENT ON TABLE  resource_requirement                   IS 'What products are needed at a location within a relief program';
COMMENT ON COLUMN resource_requirement.quantity_committed IS 'Auto-maintained by Trigger T1 when commitments are inserted/updated';
COMMENT ON COLUMN resource_requirement.quantity_fulfilled IS 'Auto-maintained by Trigger T1 when fulfillments are inserted';
COMMENT ON COLUMN resource_requirement.fulfillment_status IS 'Auto-updated by Trigger T1: Unfulfilled/Partial/Fulfilled';


-- =============================================================================
-- TABLE 8 — org_category
-- Lookup: Medical NGO, Food Relief, Shelter, Logistics, Government Unit, INGO
-- =============================================================================

CREATE TABLE org_category (
    org_category_id  SERIAL        PRIMARY KEY,
    category_name    VARCHAR(100)  NOT NULL UNIQUE,
    description      TEXT
);

COMMENT ON TABLE org_category IS 'Lookup table for organization types (Medical NGO, Food Relief, INGO, etc.)';


-- =============================================================================
-- TABLE 9 — organization
-- EER ISA specialization: GovernmentUnit | NonGovernmentOrg
-- Single-table implementation with nullable extended attribute columns
-- Italic [ISA] columns: government_tier, international_flag, registration_authority
-- approved_by_admin_id is a self-referencing FK (one org approves another)
-- =============================================================================

CREATE TABLE organization (
    org_id                  SERIAL           PRIMARY KEY,
    org_category_id         INT              NOT NULL
                                REFERENCES org_category(org_category_id)
                                ON DELETE RESTRICT,
    org_name                VARCHAR(200)     NOT NULL,
    registration_number     VARCHAR(100)     UNIQUE,
    contact_email           VARCHAR(200)     NOT NULL,
    contact_phone           VARCHAR(30),
    approval_status         approval_status  NOT NULL DEFAULT 'Pending',
    approved_by_admin_id    INT
                                REFERENCES organization(org_id)
                                ON DELETE SET NULL,
    approval_date           DATE,

    -- [ISA] GovernmentUnit extended attributes (nullable)
    government_tier         government_tier,

    -- [ISA] NonGovernmentOrg extended attributes (nullable)
    international_flag      BOOLEAN,
    registration_authority  VARCHAR(200),

    CONSTRAINT chk_approval_date
        CHECK (approval_date IS NULL OR approval_status IN ('Approved', 'Rejected'))
);

-- Now that organization exists, add the FK on relief_program
ALTER TABLE relief_program
    ADD CONSTRAINT fk_program_admin
    FOREIGN KEY (created_by_admin_id)
    REFERENCES organization(org_id)
    ON DELETE SET NULL;

COMMENT ON TABLE  organization                   IS 'Relief organizations: NGOs, INGOs, government units. ISA specialization via nullable columns.';
COMMENT ON COLUMN organization.government_tier    IS '[ISA GovernmentUnit] Federal/Provincial/District — NULL for non-government orgs';
COMMENT ON COLUMN organization.international_flag IS '[ISA NonGovOrg] TRUE if the org is an international NGO — NULL for government units';


-- =============================================================================
-- TABLE 10 — program_enrollment
-- Junction table resolving M:N between organization and relief_program
-- UNIQUE(program_id, org_id) — one org can enroll in a program only once
-- SP1 RegisterOrganizationForProgram() manages inserts atomically
-- =============================================================================

CREATE TABLE program_enrollment (
    enrollment_id     SERIAL             PRIMARY KEY,
    program_id        INT                NOT NULL
                          REFERENCES relief_program(program_id)
                          ON DELETE CASCADE,
    org_id            INT                NOT NULL
                          REFERENCES organization(org_id)
                          ON DELETE CASCADE,
    enrolled_date     DATE               NOT NULL DEFAULT CURRENT_DATE,
    enrollment_status enrollment_status  NOT NULL DEFAULT 'Active',

    CONSTRAINT uq_enrollment UNIQUE (program_id, org_id)
);

COMMENT ON TABLE program_enrollment IS 'Junction table: which organizations are enrolled in which relief programs. Managed by SP1.';


-- =============================================================================
-- TABLE 11 — commitment
-- An org commits to fulfilling a specific resource_requirement
-- Atomically paired with inventory deduction — enforced as a transaction (FR-D05)
-- =============================================================================

CREATE TABLE commitment (
    commitment_id      SERIAL             PRIMARY KEY,
    requirement_id     INT                NOT NULL
                           REFERENCES resource_requirement(requirement_id)
                           ON DELETE RESTRICT,
    org_id             INT                NOT NULL
                           REFERENCES organization(org_id)
                           ON DELETE RESTRICT,
    quantity_committed INT                NOT NULL,
    commitment_date    DATE               NOT NULL DEFAULT CURRENT_DATE,
    commitment_status  commitment_status  NOT NULL DEFAULT 'Active',
    notes              TEXT,

    CONSTRAINT chk_commitment_qty CHECK (quantity_committed > 0)
);

COMMENT ON TABLE  commitment                   IS 'An organization pledges to deliver a quantity against a resource requirement';
COMMENT ON COLUMN commitment.quantity_committed IS 'Number of units the org is committing to deliver';


-- =============================================================================
-- TABLE 12 — fulfillment
-- Records actual deliveries against a commitment (can be partial, multiple rows)
-- Trigger T1 fires AFTER INSERT here → updates resource_requirement totals
-- =============================================================================

CREATE TABLE fulfillment (
    fulfillment_id         SERIAL           PRIMARY KEY,
    commitment_id          INT              NOT NULL
                               REFERENCES commitment(commitment_id)
                               ON DELETE RESTRICT,
    quantity_fulfilled     INT              NOT NULL,
    fulfillment_date       DATE             NOT NULL DEFAULT CURRENT_DATE,
    delivery_method        delivery_method  NOT NULL,
    verified_by_admin_id   INT
                               REFERENCES organization(org_id)
                               ON DELETE SET NULL,

    CONSTRAINT chk_fulfillment_qty CHECK (quantity_fulfilled > 0)
);

COMMENT ON TABLE  fulfillment                 IS 'An actual delivery record against a commitment — multiple partials allowed per commitment';
COMMENT ON COLUMN fulfillment.quantity_fulfilled IS 'Units actually delivered in this delivery event';
COMMENT ON COLUMN fulfillment.verified_by_admin_id IS 'Optional: the admin/authority org that verified this delivery';


-- =============================================================================
-- TABLE 13 — field_team
-- A sub-unit of an organization deployed to a specific location
-- =============================================================================

CREATE TABLE field_team (
    team_id             SERIAL       PRIMARY KEY,
    org_id              INT          NOT NULL
                            REFERENCES organization(org_id)
                            ON DELETE CASCADE,
    location_id         INT          NOT NULL
                            REFERENCES disaster_location(location_id)
                            ON DELETE RESTRICT,
    team_name           VARCHAR(200) NOT NULL,
    team_leader_name    VARCHAR(200) NOT NULL,
    headcount           INT          NOT NULL DEFAULT 1,
    deployment_date     DATE         NOT NULL DEFAULT CURRENT_DATE,
    status              team_status  NOT NULL DEFAULT 'Active',

    CONSTRAINT chk_headcount CHECK (headcount > 0)
);

COMMENT ON TABLE field_team IS 'A field team deployed by an organization to a specific disaster location';


-- =============================================================================
-- TABLE 14 — incident_report
-- Field teams submit reports that feed the RAG embedding pipeline
-- report_body (TEXT) is embedded by the RAG layer for semantic search
-- =============================================================================

CREATE TABLE incident_report (
    report_id      SERIAL         PRIMARY KEY,
    team_id        INT            NOT NULL
                       REFERENCES field_team(team_id)
                       ON DELETE RESTRICT,
    location_id    INT            NOT NULL
                       REFERENCES disaster_location(location_id)
                       ON DELETE RESTRICT,
    report_title   VARCHAR(300)   NOT NULL,
    report_body    TEXT           NOT NULL,
    report_date    DATE           NOT NULL DEFAULT CURRENT_DATE,
    severity_flag  severity_flag  NOT NULL DEFAULT 'Info',
    submitted_by   VARCHAR(200)   NOT NULL
);

COMMENT ON TABLE  incident_report            IS 'Field reports submitted by teams — embedded for semantic search by the RAG pipeline';
COMMENT ON COLUMN incident_report.report_body IS 'Full report text. Embedded by NVIDIA Llama Nemotron and stored in ChromaDB.';


-- =============================================================================
-- TABLE 15 — beneficiary
-- EER: address is a COMPOSITE ATTRIBUTE (province + district + street_address)
-- Stored as separate columns to satisfy 1NF
-- WEAK ENTITY: AidDistribution depends on beneficiary + program context
-- =============================================================================

CREATE TABLE beneficiary (
    beneficiary_id       SERIAL               PRIMARY KEY,
    location_id          INT                  NOT NULL
                             REFERENCES disaster_location(location_id)
                             ON DELETE RESTRICT,
    cnic_or_id           VARCHAR(20)          NOT NULL UNIQUE,
    full_name            VARCHAR(200)         NOT NULL,
    contact_number       VARCHAR(30),
    family_size          INT                  NOT NULL DEFAULT 1,
    -- Composite address attribute (EER extension — stored as 3 separate columns)
    address_province     VARCHAR(100),
    address_district     VARCHAR(100),
    address_street       VARCHAR(300),
    registration_date    DATE                 NOT NULL DEFAULT CURRENT_DATE,
    displacement_status  displacement_status  NOT NULL DEFAULT 'Displaced',

    CONSTRAINT chk_family_size CHECK (family_size >= 1)
);

COMMENT ON TABLE  beneficiary               IS 'A registered disaster-affected individual or family unit';
COMMENT ON COLUMN beneficiary.cnic_or_id    IS 'National ID (CNIC) or system-generated ID — globally unique per beneficiary';
COMMENT ON COLUMN beneficiary.address_province IS '[Composite attribute] Province component of home address';
COMMENT ON COLUMN beneficiary.address_district IS '[Composite attribute] District component of home address';
COMMENT ON COLUMN beneficiary.address_street   IS '[Composite attribute] Street/village component of home address';


-- =============================================================================
-- TABLE 16 — aid_distribution
-- WEAK ENTITY: depends on beneficiary + relief_program + product
-- Identifying attributes: (beneficiary_id, product_id, program_id, distribution_date)
-- Tracks what was given to whom, when, by which org/team
-- =============================================================================

CREATE TABLE aid_distribution (
    distribution_id       SERIAL  PRIMARY KEY,
    beneficiary_id        INT     NOT NULL
                              REFERENCES beneficiary(beneficiary_id)
                              ON DELETE RESTRICT,
    product_id            INT     NOT NULL
                              REFERENCES product(product_id)
                              ON DELETE RESTRICT,
    program_id            INT     NOT NULL
                              REFERENCES relief_program(program_id)
                              ON DELETE RESTRICT,
    org_id                INT     NOT NULL
                              REFERENCES organization(org_id)
                              ON DELETE RESTRICT,
    team_id               INT
                              REFERENCES field_team(team_id)
                              ON DELETE SET NULL,
    quantity_distributed  INT     NOT NULL,
    distribution_date     DATE    NOT NULL DEFAULT CURRENT_DATE,
    notes                 TEXT,

    -- Weak entity identifying constraint: prevent duplicate distributions
    CONSTRAINT uq_distribution
        UNIQUE (beneficiary_id, product_id, program_id, distribution_date),

    CONSTRAINT chk_distribution_qty CHECK (quantity_distributed > 0)
);

COMMENT ON TABLE  aid_distribution IS 'WEAK ENTITY: records of aid given to a beneficiary — depends on beneficiary + program context';
COMMENT ON COLUMN aid_distribution.team_id IS 'Optional: the specific field team that made this distribution';


-- =============================================================================
-- TABLE 17 — audit_log
-- Generic audit table — populated exclusively by Triggers T1 and T2
-- No FK back to other tables (intentional — flexible across all tables)
-- old_value and new_value stored as JSON text for schema flexibility
-- =============================================================================

CREATE TABLE audit_log (
    log_id            SERIAL        PRIMARY KEY,
    table_name        VARCHAR(100)  NOT NULL,
    record_id         INT           NOT NULL,
    action_type       audit_action  NOT NULL,
    old_value         TEXT,          -- JSON string of changed fields (before)
    new_value         TEXT,          -- JSON string of changed fields (after)
    changed_by        VARCHAR(200),  -- username or system identifier
    change_timestamp  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  audit_log            IS 'Generic audit trail — populated by Trigger T2 (severity changes) and Trigger T1 (status changes)';
COMMENT ON COLUMN audit_log.old_value  IS 'JSON representation of old field values before the change';
COMMENT ON COLUMN audit_log.new_value  IS 'JSON representation of new field values after the change';


-- =============================================================================
-- SECTION 2 — INDEXES
-- Rule: index every FK column + all high-frequency filter columns
-- =============================================================================

-- disaster
CREATE INDEX idx_disaster_type        ON disaster(disaster_type_id);
CREATE INDEX idx_disaster_status      ON disaster(status);
CREATE INDEX idx_disaster_severity    ON disaster(severity_level);

-- disaster_location
CREATE INDEX idx_dloc_disaster        ON disaster_location(disaster_id);
CREATE INDEX idx_dloc_status          ON disaster_location(location_status);
CREATE INDEX idx_dloc_province        ON disaster_location(province);
CREATE INDEX idx_dloc_district        ON disaster_location(district);

-- relief_camp
CREATE INDEX idx_camp_location        ON relief_camp(location_id);

-- relief_program
CREATE INDEX idx_rp_disaster          ON relief_program(disaster_id);
CREATE INDEX idx_rp_status            ON relief_program(status);
CREATE INDEX idx_rp_admin             ON relief_program(created_by_admin_id);

-- product
CREATE INDEX idx_product_category     ON product(category);

-- resource_requirement
CREATE INDEX idx_rr_program           ON resource_requirement(program_id);
CREATE INDEX idx_rr_location          ON resource_requirement(location_id);
CREATE INDEX idx_rr_product           ON resource_requirement(product_id);
CREATE INDEX idx_rr_status            ON resource_requirement(fulfillment_status);
CREATE INDEX idx_rr_priority          ON resource_requirement(priority);

-- organization
CREATE INDEX idx_org_category         ON organization(org_category_id);
CREATE INDEX idx_org_approval         ON organization(approval_status);
CREATE INDEX idx_org_approved_by      ON organization(approved_by_admin_id);

-- program_enrollment
CREATE INDEX idx_pe_program           ON program_enrollment(program_id);
CREATE INDEX idx_pe_org               ON program_enrollment(org_id);
CREATE INDEX idx_pe_status            ON program_enrollment(enrollment_status);

-- commitment
CREATE INDEX idx_com_requirement      ON commitment(requirement_id);
CREATE INDEX idx_com_org              ON commitment(org_id);
CREATE INDEX idx_com_status           ON commitment(commitment_status);

-- fulfillment
CREATE INDEX idx_ful_commitment       ON fulfillment(commitment_id);
CREATE INDEX idx_ful_date             ON fulfillment(fulfillment_date);
CREATE INDEX idx_ful_verified_by      ON fulfillment(verified_by_admin_id);

-- field_team
CREATE INDEX idx_ft_org               ON field_team(org_id);
CREATE INDEX idx_ft_location          ON field_team(location_id);
CREATE INDEX idx_ft_status            ON field_team(status);

-- incident_report
CREATE INDEX idx_ir_team              ON incident_report(team_id);
CREATE INDEX idx_ir_location          ON incident_report(location_id);
CREATE INDEX idx_ir_date              ON incident_report(report_date);
CREATE INDEX idx_ir_severity          ON incident_report(severity_flag);

-- beneficiary
CREATE INDEX idx_ben_location         ON beneficiary(location_id);
CREATE INDEX idx_ben_displacement     ON beneficiary(displacement_status);
CREATE INDEX idx_ben_registration     ON beneficiary(registration_date);

-- aid_distribution
CREATE INDEX idx_ad_beneficiary       ON aid_distribution(beneficiary_id);
CREATE INDEX idx_ad_product           ON aid_distribution(product_id);
CREATE INDEX idx_ad_program           ON aid_distribution(program_id);
CREATE INDEX idx_ad_org               ON aid_distribution(org_id);
CREATE INDEX idx_ad_team              ON aid_distribution(team_id);
CREATE INDEX idx_ad_date              ON aid_distribution(distribution_date);

-- audit_log
CREATE INDEX idx_al_table             ON audit_log(table_name);
CREATE INDEX idx_al_record            ON audit_log(record_id);
CREATE INDEX idx_al_timestamp         ON audit_log(change_timestamp);
CREATE INDEX idx_al_action            ON audit_log(action_type);


-- =============================================================================
-- SECTION 3 — TRIGGER T1
-- AFTER INSERT on fulfillment:
--   1. Recalculate quantity_fulfilled on the parent resource_requirement
--   2. Recalculate quantity_committed on the parent resource_requirement
--   3. Update fulfillment_status to Unfulfilled / Partial / Fulfilled
--   4. Write a record to audit_log
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_update_requirement_on_fulfillment()
RETURNS TRIGGER AS $$
DECLARE
    v_requirement_id    INT;
    v_qty_required      INT;
    v_new_fulfilled     INT;
    v_new_committed     INT;
    v_new_status        fulfillment_status;
    v_old_status        fulfillment_status;
BEGIN
    -- Step 1: Find the requirement_id via the commitment
    SELECT requirement_id
      INTO v_requirement_id
      FROM commitment
     WHERE commitment_id = NEW.commitment_id;

    -- Step 2: Recalculate totals across ALL fulfillments for this requirement
    SELECT
        COALESCE(SUM(f.quantity_fulfilled), 0),
        COALESCE(SUM(c.quantity_committed), 0)
      INTO v_new_fulfilled, v_new_committed
      FROM fulfillment f
      JOIN commitment  c ON c.commitment_id = f.commitment_id
     WHERE c.requirement_id = v_requirement_id
       AND c.commitment_status != 'Cancelled';

    -- Step 3: Determine new fulfillment_status
    SELECT quantity_required, fulfillment_status
      INTO v_qty_required, v_old_status
      FROM resource_requirement
     WHERE requirement_id = v_requirement_id;

    IF v_new_fulfilled = 0 THEN
        v_new_status := 'Unfulfilled';
    ELSIF v_new_fulfilled >= v_qty_required THEN
        v_new_status := 'Fulfilled';
    ELSE
        v_new_status := 'Partial';
    END IF;

    -- Step 4: Update the resource_requirement row
    UPDATE resource_requirement
       SET quantity_fulfilled  = v_new_fulfilled,
           quantity_committed  = v_new_committed,
           fulfillment_status  = v_new_status
     WHERE requirement_id = v_requirement_id;

    -- Step 5: Write to audit_log only if status changed
    IF v_old_status IS DISTINCT FROM v_new_status THEN
        INSERT INTO audit_log(
            table_name, record_id, action_type,
            old_value,  new_value, changed_by
        ) VALUES (
            'resource_requirement',
            v_requirement_id,
            'UPDATE',
            json_build_object('fulfillment_status', v_old_status)::TEXT,
            json_build_object('fulfillment_status', v_new_status,
                              'quantity_fulfilled',  v_new_fulfilled)::TEXT,
            'TRIGGER_T1'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_t1_update_fulfillment_status
    AFTER INSERT ON fulfillment
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_requirement_on_fulfillment();

COMMENT ON FUNCTION fn_update_requirement_on_fulfillment() IS
    'Trigger T1: fires after each fulfillment insert, recalculates totals and status on resource_requirement';


-- =============================================================================
-- SECTION 4 — TRIGGER T2
-- AFTER UPDATE of severity_level on disaster:
--   Automatically inserts into audit_log with old and new values
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_audit_disaster_severity()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.severity_level IS DISTINCT FROM NEW.severity_level THEN
        INSERT INTO audit_log(
            table_name,  record_id,   action_type,
            old_value,   new_value,   changed_by
        ) VALUES (
            'disaster',
            NEW.disaster_id,
            'UPDATE',
            json_build_object('severity_level', OLD.severity_level)::TEXT,
            json_build_object('severity_level', NEW.severity_level)::TEXT,
            current_user
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_t2_audit_severity
    AFTER UPDATE OF severity_level ON disaster
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_disaster_severity();

COMMENT ON FUNCTION fn_audit_disaster_severity() IS
    'Trigger T2: fires after any update to disaster.severity_level, writes old/new to audit_log';


-- =============================================================================
-- SECTION 5 — STORED PROCEDURE SP1
-- RegisterOrganizationForProgram(p_org_id, p_program_id)
-- Validates:
--   1. Organization exists and is Approved
--   2. Program exists and is Active
--   3. Organization is not already enrolled
-- Then inserts into program_enrollment atomically
-- =============================================================================

CREATE OR REPLACE PROCEDURE sp_register_org_for_program(
    p_org_id     INT,
    p_program_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_approval  approval_status;
    v_prog_status program_status;
    v_existing  INT;
BEGIN
    -- Check 1: org exists and is Approved
    SELECT approval_status
      INTO v_approval
      FROM organization
     WHERE org_id = p_org_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Organization % does not exist', p_org_id;
    END IF;

    IF v_approval != 'Approved' THEN
        RAISE EXCEPTION 'Organization % is not approved (status: %)', p_org_id, v_approval;
    END IF;

    -- Check 2: program exists and is Active
    SELECT status
      INTO v_prog_status
      FROM relief_program
     WHERE program_id = p_program_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Relief program % does not exist', p_program_id;
    END IF;

    IF v_prog_status != 'Active' THEN
        RAISE EXCEPTION 'Relief program % is not active (status: %)', p_program_id, v_prog_status;
    END IF;

    -- Check 3: not already enrolled
    SELECT COUNT(*)
      INTO v_existing
      FROM program_enrollment
     WHERE org_id = p_org_id AND program_id = p_program_id;

    IF v_existing > 0 THEN
        RAISE EXCEPTION 'Organization % is already enrolled in program %', p_org_id, p_program_id;
    END IF;

    -- All checks passed — insert enrollment
    INSERT INTO program_enrollment(program_id, org_id, enrolled_date, enrollment_status)
    VALUES (p_program_id, p_org_id, CURRENT_DATE, 'Active');

    RAISE NOTICE 'Organization % successfully enrolled in program %', p_org_id, p_program_id;
END;
$$;

COMMENT ON PROCEDURE sp_register_org_for_program IS
    'SP1: Atomically enrolls an approved organization into an active relief program with all validation checks';


-- =============================================================================
-- SECTION 6 — STORED PROCEDURE SP2
-- GenerateRequirementGapReport(p_program_id, p_threshold_pct)
-- Returns all requirements in a program where fulfillment % < threshold
-- Ordered by gap size descending (most critical first)
-- =============================================================================

CREATE OR REPLACE FUNCTION sp_requirement_gap_report(
    p_program_id    INT,
    p_threshold_pct NUMERIC DEFAULT 70
)
RETURNS TABLE (
    requirement_id      INT,
    location_district   VARCHAR,
    product_name        VARCHAR,
    quantity_required   INT,
    quantity_fulfilled  INT,
    fulfillment_pct     NUMERIC,
    gap_units           INT,
    priority            priority_level
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        rr.requirement_id,
        dl.district::VARCHAR,
        p.product_name::VARCHAR,
        rr.quantity_required,
        rr.quantity_fulfilled,
        ROUND(
            (rr.quantity_fulfilled::NUMERIC / NULLIF(rr.quantity_required, 0)) * 100,
            2
        ) AS fulfillment_pct,
        (rr.quantity_required - rr.quantity_fulfilled) AS gap_units,
        rr.priority
    FROM resource_requirement rr
    JOIN disaster_location dl ON dl.location_id = rr.location_id
    JOIN product           p  ON p.product_id   = rr.product_id
    WHERE rr.program_id = p_program_id
      AND (
            rr.quantity_fulfilled::NUMERIC
            / NULLIF(rr.quantity_required, 0)
          ) * 100 < p_threshold_pct
    ORDER BY gap_units DESC, rr.priority DESC;
END;
$$;

COMMENT ON FUNCTION sp_requirement_gap_report IS
    'SP2: Returns resource requirements below the fulfillment threshold, ordered by gap size';


-- =============================================================================
-- SECTION 7 — VIEWS (FR-D07)
-- =============================================================================

-- View 1: ActiveProgramSummary
-- Shows all active programs with disaster context and enrollment count
CREATE OR REPLACE VIEW v_active_program_summary AS
SELECT
    rp.program_id,
    rp.program_name,
    d.disaster_name,
    d.severity_level,
    rp.start_date,
    rp.end_date,
    rp.status,
    COUNT(DISTINCT pe.org_id) AS enrolled_org_count,
    COUNT(DISTINCT rr.requirement_id) AS total_requirements
FROM relief_program rp
JOIN disaster d ON d.disaster_id = rp.disaster_id
LEFT JOIN program_enrollment pe ON pe.program_id = rp.program_id
    AND pe.enrollment_status = 'Active'
LEFT JOIN resource_requirement rr ON rr.program_id = rp.program_id
WHERE rp.status = 'Active'
GROUP BY rp.program_id, rp.program_name, d.disaster_name,
         d.severity_level, rp.start_date, rp.end_date, rp.status;

COMMENT ON VIEW v_active_program_summary IS 'All active relief programs with enrollment counts and requirement counts';


-- View 2: OrgFulfillmentLeaderboard
-- Ranks organizations by total units delivered across all programs
CREATE OR REPLACE VIEW v_org_fulfillment_leaderboard AS
SELECT
    o.org_id,
    o.org_name,
    oc.category_name,
    COUNT(DISTINCT c.commitment_id)      AS total_commitments,
    COALESCE(SUM(f.quantity_fulfilled), 0) AS total_units_delivered,
    COALESCE(SUM(c.quantity_committed), 0) AS total_units_committed,
    ROUND(
        COALESCE(SUM(f.quantity_fulfilled), 0)::NUMERIC
        / NULLIF(SUM(c.quantity_committed), 0) * 100,
        2
    ) AS reliability_pct
FROM organization o
JOIN org_category oc ON oc.org_category_id = o.org_category_id
LEFT JOIN commitment  c ON c.org_id = o.org_id AND c.commitment_status != 'Cancelled'
LEFT JOIN fulfillment f ON f.commitment_id = c.commitment_id
GROUP BY o.org_id, o.org_name, oc.category_name
ORDER BY total_units_delivered DESC;

COMMENT ON VIEW v_org_fulfillment_leaderboard IS 'Organizations ranked by total units delivered with reliability percentage';


-- View 3: BeneficiaryAidHistory
-- Full aid distribution history per beneficiary
CREATE OR REPLACE VIEW v_beneficiary_aid_history AS
SELECT
    b.beneficiary_id,
    b.full_name,
    b.cnic_or_id,
    b.family_size,
    dl.district,
    dl.province,
    p.product_name,
    p.category        AS product_category,
    p.unit_of_measure,
    ad.quantity_distributed,
    ad.distribution_date,
    o.org_name        AS distributing_org,
    ft.team_name      AS distributing_team,
    rp.program_name
FROM beneficiary b
JOIN disaster_location dl ON dl.location_id  = b.location_id
JOIN aid_distribution  ad ON ad.beneficiary_id = b.beneficiary_id
JOIN product           p  ON p.product_id    = ad.product_id
JOIN organization      o  ON o.org_id        = ad.org_id
JOIN relief_program    rp ON rp.program_id   = ad.program_id
LEFT JOIN field_team   ft ON ft.team_id      = ad.team_id
ORDER BY b.beneficiary_id, ad.distribution_date;

COMMENT ON VIEW v_beneficiary_aid_history IS 'Complete aid distribution history for every beneficiary';


-- View 4: RequirementGapView
-- All requirements across active programs with fulfillment percentage
CREATE OR REPLACE VIEW v_requirement_gap AS
SELECT
    rr.requirement_id,
    rp.program_name,
    d.disaster_name,
    dl.province,
    dl.district,
    p.product_name,
    p.unit_of_measure,
    rr.quantity_required,
    rr.quantity_committed,
    rr.quantity_fulfilled,
    ROUND(
        rr.quantity_fulfilled::NUMERIC / NULLIF(rr.quantity_required, 0) * 100,
        2
    ) AS fulfillment_pct,
    (rr.quantity_required - rr.quantity_fulfilled) AS gap_units,
    rr.fulfillment_status,
    rr.priority
FROM resource_requirement rr
JOIN relief_program    rp ON rp.program_id  = rr.program_id
JOIN disaster          d  ON d.disaster_id  = rp.disaster_id
JOIN disaster_location dl ON dl.location_id = rr.location_id
JOIN product           p  ON p.product_id   = rr.product_id
WHERE rp.status = 'Active'
ORDER BY gap_units DESC, rr.priority DESC;

COMMENT ON VIEW v_requirement_gap IS 'All resource requirements in active programs with fulfillment percentage and gap units';


-- View 5: DisasterImpactSummary
-- High-level impact metrics per disaster
CREATE OR REPLACE VIEW v_disaster_impact_summary AS
SELECT
    d.disaster_id,
    d.disaster_name,
    dt.type_name         AS disaster_type,
    d.severity_level,
    d.declaration_date,
    d.status,
    COUNT(DISTINCT dl.location_id)     AS affected_locations,
    COALESCE(SUM(dl.affected_population), 0) AS total_affected_population,
    COUNT(DISTINCT b.beneficiary_id)   AS registered_beneficiaries,
    COUNT(DISTINCT pe.org_id)          AS active_organizations,
    COALESCE(SUM(ad.quantity_distributed), 0) AS total_units_distributed
FROM disaster d
JOIN disaster_type     dt ON dt.disaster_type_id = d.disaster_type_id
LEFT JOIN disaster_location dl ON dl.disaster_id  = d.disaster_id
LEFT JOIN beneficiary      b  ON b.location_id    = dl.location_id
LEFT JOIN relief_program   rp ON rp.disaster_id   = d.disaster_id
LEFT JOIN program_enrollment pe ON pe.program_id  = rp.program_id
    AND pe.enrollment_status = 'Active'
LEFT JOIN aid_distribution ad ON ad.program_id    = rp.program_id
GROUP BY d.disaster_id, d.disaster_name, dt.type_name,
         d.severity_level, d.declaration_date, d.status
ORDER BY d.declaration_date DESC;

COMMENT ON VIEW v_disaster_impact_summary IS 'High-level impact metrics per disaster: affected population, beneficiaries, orgs, units distributed';


-- =============================================================================
-- MIGRATION COMPLETE
-- Run with: supabase db reset
-- Verify with: supabase db reset && psql $DB_URL -c "\dt"
-- =============================================================================
