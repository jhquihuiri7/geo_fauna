/* Admin shared utilities */
const { useState, useEffect, useRef, useMemo } = React;

function Icon({ name, fill = false, className = "", style = {} }) {
  return (
    <span
      className={"material-symbols-outlined " + (fill ? "msf " : "") + className}
      style={style}
    >{name}</span>
  );
}

function Avatar({ name, size = 36, tone = "primary", emoji }) {
  const palette = {
    primary:  ["#006948", "#85f8c4"],
    emerald:  ["#005137", "#68dba9"],
    blue:     ["#00628d", "#c9e6ff"],
    slate:    ["#3a485c", "#d5e3fd"],
    sand:     ["#7a5a2e", "#f3e0bd"],
    coral:    ["#a33b2a", "#ffd9cf"],
    forest:   ["#2c4734", "#a8d2b3"],
    teal:     ["#005f5f", "#a3e0e0"],
    rose:     ["#7d2e4e", "#ffb3d1"],
    olive:    ["#4a521a", "#d4dfb0"],
  };
  const [bg, fg] = palette[tone] || palette.primary;
  const initials = name
    ? name.split(" ").map(w => w[0]).slice(0, 2).join("").toUpperCase()
    : "";
  return (
    <div
      className="avatar"
      style={{ width: size, height: size, background: bg, color: fg, fontSize: size * 0.4 }}
    >
      {emoji ? <span style={{ fontSize: size * 0.55 }}>{emoji}</span> : initials}
    </div>
  );
}

function Chip({ children, tone = "primary", size = "md" }) {
  const styles = {
    primary:  { bg: "color-mix(in oklab, var(--primary) 12%, transparent)", fg: "var(--primary)" },
    tertiary: { bg: "color-mix(in oklab, var(--tertiary) 12%, transparent)", fg: "var(--tertiary)" },
    emerald:  { bg: "color-mix(in oklab, var(--primary-fixed-dim) 22%, transparent)", fg: "var(--primary)" },
    slate:    { bg: "var(--surface-container-high)", fg: "var(--on-surface-variant)" },
    error:    { bg: "var(--error-container)", fg: "var(--on-error-container)" },
    warning:  { bg: "color-mix(in oklab, var(--warning) 18%, transparent)", fg: "var(--warning)" },
    rose:     { bg: "color-mix(in oklab, #ec4899 18%, transparent)", fg: "#be185d" },
    outline:  { bg: "transparent", fg: "var(--on-surface-variant)", border: "1px solid var(--outline-variant)" },
  };
  const s = styles[tone] || styles.primary;
  const sizes = {
    sm: { padding: "3px 8px", fontSize: 9 },
    md: { padding: "4px 11px", fontSize: 10 },
    lg: { padding: "6px 14px", fontSize: 11 },
  };
  return (
    <span
      style={{
        background: s.bg, color: s.fg, border: s.border,
        borderRadius: 9999, fontWeight: 900,
        textTransform: "uppercase", letterSpacing: "0.1em",
        whiteSpace: "nowrap", display: "inline-flex", alignItems: "center", gap: 6,
        ...sizes[size],
      }}
    >{children}</span>
  );
}

function Card({ children, className = "", style = {}, ...rest }) {
  return (
    <div
      className={"bg-sc-lowest shadow-card " + className}
      style={{ borderRadius: 24, padding: 24, ...style }}
      {...rest}
    >{children}</div>
  );
}

function Kicker({ children, action }) {
  return (
    <div className="flex items-center justify-between mb-4">
      <h3 className="text-[11px] font-extrabold uppercase tracking-[0.15em] text-on-surface-variant">{children}</h3>
      {action}
    </div>
  );
}

function Btn({ children, variant = "primary", icon, iconRight, onClick, size = "md", className = "", style = {} }) {
  const sizes = {
    sm: { height: 34, padding: "0 14px", fontSize: 12, gap: 6 },
    md: { height: 40, padding: "0 18px", fontSize: 13, gap: 8 },
    lg: { height: 48, padding: "0 22px", fontSize: 14, gap: 8 },
  };
  const variants = {
    primary: { background: "var(--primary)", color: "var(--on-primary)", fontWeight: 800 },
    gradient: { background: "linear-gradient(135deg, var(--primary), var(--primary-container))", color: "#fff", fontWeight: 800, boxShadow: "0 6px 18px color-mix(in oklab, var(--primary) 25%, transparent)" },
    secondary: { background: "var(--surface-container-high)", color: "var(--on-surface)", fontWeight: 700 },
    ghost: { background: "transparent", color: "var(--on-surface)", fontWeight: 700 },
    danger: { background: "var(--error-container)", color: "var(--on-error-container)", fontWeight: 800 },
    success: { background: "color-mix(in oklab, var(--primary) 14%, transparent)", color: "var(--primary)", fontWeight: 800 },
  };
  return (
    <button
      onClick={onClick}
      className={"inline-flex items-center justify-center " + className}
      style={{ borderRadius: 9999, ...sizes[size], ...variants[variant], ...style }}
    >
      {icon && <Icon name={icon} className="text-[16px]" />}
      <span>{children}</span>
      {iconRight && <Icon name={iconRight} className="text-[16px]" />}
    </button>
  );
}

function StatCard({ label, value, delta, deltaTone = "primary", icon, iconTone = "primary" }) {
  const iconBg = {
    primary: "color-mix(in oklab, var(--primary) 12%, transparent)",
    tertiary: "color-mix(in oklab, var(--tertiary) 12%, transparent)",
    warning: "color-mix(in oklab, var(--warning) 18%, transparent)",
    error: "var(--error-container)",
  }[iconTone];
  const iconColor = {
    primary: "var(--primary)",
    tertiary: "var(--tertiary)",
    warning: "var(--warning)",
    error: "var(--error)",
  }[iconTone];
  return (
    <Card>
      <div className="flex items-start justify-between mb-4">
        <div className="text-[10px] font-extrabold uppercase tracking-[0.15em] text-on-surface-variant">{label}</div>
        <div className="flex items-center justify-center" style={{
          width: 36, height: 36, borderRadius: 12, background: iconBg, color: iconColor,
        }}>
          <Icon name={icon} className="text-[20px]" />
        </div>
      </div>
      <div className="text-3xl font-black tracking-tighter text-on-surface">{value}</div>
      {delta && (
        <div className="text-[11px] font-extrabold mt-2 flex items-center gap-1"
          style={{ color: deltaTone === "error" ? "var(--error)" : deltaTone === "tertiary" ? "var(--tertiary)" : "var(--primary)" }}>
          <Icon name={deltaTone === "error" ? "trending_down" : "trending_up"} className="text-[14px]" />
          {delta}
        </div>
      )}
    </Card>
  );
}

function SearchBar({ placeholder = "Buscar…", value, onChange }) {
  return (
    <div className="bg-sc-low flex items-center gap-3 px-4" style={{ borderRadius: 9999, height: 40, minWidth: 280 }}>
      <Icon name="search" className="text-outline text-[18px]" />
      <input
        className="bg-transparent outline-none flex-1 text-sm text-on-surface placeholder:text-outline"
        placeholder={placeholder}
        value={value || ""}
        onChange={onChange || (() => {})}
      />
    </div>
  );
}

function Switch({ on, onChange }) {
  return (
    <span
      role="switch"
      aria-checked={on}
      tabIndex={0}
      onClick={() => onChange && onChange(!on)}
      className={"switch " + (on ? "on" : "")}
    />
  );
}

// Table primitives
function Table({ children }) {
  return (
    <div style={{ overflowX: "auto" }}>
      <table style={{ width: "100%", borderCollapse: "separate", borderSpacing: 0 }}>
        {children}
      </table>
    </div>
  );
}
function TH({ children, w, align = "left" }) {
  return (
    <th style={{
      textAlign: align, padding: "12px 14px", fontSize: 10, letterSpacing: "0.12em",
      textTransform: "uppercase", color: "var(--on-surface-variant)", fontWeight: 800,
      borderBottom: "1px solid var(--surface-container)",
      width: w,
    }}>{children}</th>
  );
}
function TD({ children, align = "left", className = "", style = {} }) {
  return (
    <td
      className={className}
      style={{
        textAlign: align, padding: "14px 14px", fontSize: 13,
        color: "var(--on-surface)",
        borderBottom: "1px solid var(--surface-container)",
        ...style,
      }}
    >{children}</td>
  );
}

Object.assign(window, { Icon, Avatar, Chip, Card, Kicker, Btn, StatCard, SearchBar, Switch, Table, TH, TD });
