PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS physicians (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  employment_status TEXT NOT NULL DEFAULT 'active'
    CHECK (employment_status IN ('active','inactive','left')),
  start_date TEXT,
  end_date TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('SUPERADMIN','ADMIN','ADMINISTRATIVO','FACULTATIVO')),
  physician_id TEXT UNIQUE REFERENCES physicians(id),
  password_hash TEXT,
  active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0,1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS physician_contract_periods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  start_month TEXT NOT NULL,
  end_month TEXT,
  pct REAL NOT NULL CHECK (pct BETWEEN 0 AND 100),
  UNIQUE (physician_id, start_month)
);

CREATE TABLE IF NOT EXISTS physician_restrictions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  restriction TEXT NOT NULL,
  value_json TEXT NOT NULL DEFAULT '{}',
  UNIQUE (physician_id, restriction)
);

CREATE TABLE IF NOT EXISTS service_settings (
  id INTEGER PRIMARY KEY CHECK (id=1),
  year INTEGER NOT NULL,
  settings_json TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  updated_by TEXT REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS holidays (
  date TEXT PRIMARY KEY,
  label TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS assignment_codes (
  code TEXT PRIMARY KEY,
  slot TEXT NOT NULL CHECK (slot IN ('m','t','f')),
  category TEXT,
  active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0,1))
);

CREATE TABLE IF NOT EXISTS assignments (
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  date TEXT NOT NULL,
  m TEXT, t TEXT, f TEXT,
  updated_at TEXT NOT NULL,
  updated_by TEXT REFERENCES users(id),
  PRIMARY KEY (physician_id,date)
);

CREATE TABLE IF NOT EXISTS official_months (
  month TEXT PRIMARY KEY,
  official_at TEXT NOT NULL,
  created_by TEXT REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS official_assignments (
  month TEXT NOT NULL REFERENCES official_months(month),
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  date TEXT NOT NULL,
  m TEXT, t TEXT, f TEXT,
  PRIMARY KEY (month,physician_id,date)
);

CREATE TABLE IF NOT EXISTS residents (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS resident_assignments (
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  date TEXT NOT NULL,
  slot TEXT NOT NULL CHECK (slot IN ('m','t','f')),
  resident_code TEXT NOT NULL REFERENCES residents(code),
  PRIMARY KEY (physician_id,date,slot)
);

CREATE TABLE IF NOT EXISTS resident_blocked_days (
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  date TEXT NOT NULL,
  resident_code TEXT NOT NULL REFERENCES residents(code),
  PRIMARY KEY (physician_id,date,resident_code)
);

CREATE TABLE IF NOT EXISTS resident_guards (
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  date TEXT NOT NULL,
  guard_type TEXT NOT NULL CHECK (guard_type IN ('puerta','observacion','fuera')),
  PRIMARY KEY (physician_id,date)
);

CREATE TABLE IF NOT EXISTS traffic_assignments (
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  date TEXT NOT NULL,
  slot TEXT NOT NULL CHECK (slot IN ('m','t','f')),
  time TEXT NOT NULL,
  PRIMARY KEY (physician_id,date,slot)
);

CREATE TABLE IF NOT EXISTS days_off (
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  date TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'manual',
  PRIMARY KEY (physician_id,date)
);

CREATE TABLE IF NOT EXISTS requests (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  physician_id TEXT REFERENCES physicians(id),
  status TEXT NOT NULL CHECK (status IN ('pendiente','aprobada','rechazada','cancelada','ejecutada')),
  version INTEGER,
  payload_json TEXT NOT NULL,
  fingerprint TEXT NOT NULL,
  submitted_at TEXT NOT NULL,
  decided_at TEXT,
  decided_by TEXT REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS request_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  request_id TEXT NOT NULL REFERENCES requests(id),
  event_type TEXT NOT NULL,
  actor_user_id TEXT REFERENCES users(id),
  event_at TEXT NOT NULL,
  data_json TEXT
);

CREATE TABLE IF NOT EXISTS admin_month_closures (
  month TEXT PRIMARY KEY,
  closed_at TEXT NOT NULL,
  closed_by TEXT REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS admin_changes (
  id TEXT PRIMARY KEY,
  month TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pendiente','ejecutado','cancelado')),
  created_at TEXT NOT NULL,
  created_by TEXT REFERENCES users(id),
  executed_at TEXT,
  executed_by TEXT REFERENCES users(id),
  notes TEXT
);

CREATE TABLE IF NOT EXISTS admin_change_cells (
  change_id TEXT NOT NULL REFERENCES admin_changes(id),
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  date TEXT NOT NULL,
  slot TEXT NOT NULL CHECK (slot IN ('m','t','f')),
  previous_value TEXT,
  requested_value TEXT,
  PRIMARY KEY (change_id,physician_id,date,slot)
);

CREATE TABLE IF NOT EXISTS traffic_notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL,
  action TEXT NOT NULL,
  physician_id TEXT REFERENCES physicians(id),
  date TEXT, slot TEXT, code TEXT, time TEXT, viewed_at TEXT
);

CREATE TABLE IF NOT EXISTS history_snapshots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  month TEXT NOT NULL,
  saved_at TEXT NOT NULL,
  snapshot_json TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS calendar_tokens (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  physician_id TEXT NOT NULL REFERENCES physicians(id),
  token_hash TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  revoked_at TEXT,
  last_used_at TEXT
);

CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  actor_user_id TEXT REFERENCES users(id),
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id TEXT,
  created_at TEXT NOT NULL,
  metadata_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_physicians_status ON physicians(employment_status);
CREATE INDEX IF NOT EXISTS idx_assignments_date ON assignments(date);
CREATE INDEX IF NOT EXISTS idx_requests_status ON requests(status);
CREATE INDEX IF NOT EXISTS idx_history_month ON history_snapshots(month);
CREATE INDEX IF NOT EXISTS idx_audit_created_at ON audit_log(created_at);
