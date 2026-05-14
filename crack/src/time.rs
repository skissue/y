use chrono::{DateTime, Local, SecondsFormat};

/// Current local time formatted as RFC 3339 with seconds precision and offset.
pub fn now_rfc3339() -> String {
    Local::now().to_rfc3339_opts(SecondsFormat::Secs, false)
}

/// Parse an RFC 3339 timestamp produced by [`now_rfc3339`].
pub fn parse_rfc3339(s: &str) -> Result<DateTime<Local>, chrono::ParseError> {
    DateTime::parse_from_rfc3339(s).map(|dt| dt.with_timezone(&Local))
}
