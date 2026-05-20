/* Shared UI components for EcoGuía prototype */
const { useState, useEffect, useRef, useMemo } = React;

// ------------ Icon ------------
function Icon({ name, fill = false, className = "", style = {} }) {
  return (
    <span
      className={"material-symbols-outlined " + (fill ? "msf " : "") + className}
      style={style}
    >{name}</span>
  );
}

// ------------ Avatar (monogram or emoji) ------------
function Avatar({ name, size = 40, tone = "primary", emoji, status, className = "" }) {
  const palette = {
    primary:   ["#006948", "#85f8c4"],
    emerald:   ["#005137", "#68dba9"],
    blue:      ["#00628d", "#c9e6ff"],
    slate:     ["#3a485c", "#d5e3fd"],
    sand:      ["#7a5a2e", "#f3e0bd"],
    coral:     ["#a33b2a", "#ffd9cf"],
    forest:    ["#2c4734", "#a8d2b3"],
    teal:      ["#005f5f", "#a3e0e0"],
  };
  const [bg, fg] = palette[tone] || palette.primary;
  const initials = name
    ? name.split(" ").map(w => w[0]).slice(0, 2).join("").toUpperCase()
    : "";
  return (
    <div
      className={"avatar " + className}
      style={{ width: size, height: size, background: bg, color: fg, fontSize: size * 0.4 }}
    >
      {emoji ? <span style={{ fontSize: size * 0.55 }}>{emoji}</span> : initials}
      {status && (
        <span
          style={{
            position: "absolute",
            bottom: 0,
            right: 0,
            width: size * 0.28,
            height: size * 0.28,
            background: status === "on" ? "#22c55e" : "#3b82f6",
            borderRadius: 9999,
            border: "2px solid var(--surface-container-lowest)",
          }}
        />
      )}
    </div>
  );
}

// ------------ PhotoPlaceholder ------------
function Photo({ tone = 1, label = "FIELD IMAGE", aspect = "16/10", className = "", style = {}, emoji }) {
  return (
    <div
      className={"photo-ph " + (tone === 2 ? "tone-2" : tone === 3 ? "tone-3" : "") + " " + className}
      style={{ aspectRatio: aspect, ...style }}
    >
      {emoji && (
        <div style={{
          position: "absolute", inset: 0,
          display: "flex", alignItems: "center", justifyContent: "center",
          fontSize: 72, opacity: 0.6
        }}>{emoji}</div>
      )}
      <div className="ph-label">{label}</div>
    </div>
  );
}

// ------------ TopBar (in-phone) ------------
function TopBar({ title, leading, trailing, sticky = true, glass = true, subtitle, large = false }) {
  return (
    <header
      className={(glass ? "glass " : "bg-surface ") + (sticky ? "sticky " : "")}
      style={{
        top: 44,
        zIndex: 40,
        padding: "12px 20px 14px",
        borderBottomLeftRadius: 28,
        borderBottomRightRadius: 28,
      }}
    >
      <div className="flex items-center justify-between gap-3">
        <div className="flex items-center gap-3 min-w-0">
          {leading}
          <div className="min-w-0">
            <div className={(large ? "text-xl " : "text-base ") + "font-black tracking-tight text-on-surface truncate"}>
              {title}
            </div>
            {subtitle && (
              <div className="text-[10px] font-bold text-on-surface-variant flex items-center gap-1 mt-0.5">
                {subtitle}
              </div>
            )}
          </div>
        </div>
        <div className="flex items-center gap-2">{trailing}</div>
      </div>
    </header>
  );
}

// ------------ Bottom nav ------------
function BottomNav({ active, onNav }) {
  const items = [
    { key: "dashboard", label: "Inicio", icon: "dashboard" },
    { key: "agenda", label: "Agenda", icon: "event_note" },
    { key: "nuevo", label: "Nuevo", icon: "add" },
    { key: "muro", label: "Muro", icon: "forum", badge: 3 },
    { key: "perfil", label: "Perfil", icon: "person" },
  ];
  return (
    <nav
      className="glass"
      style={{
        position: "absolute",
        bottom: 0, left: 0, right: 0,
        display: "flex",
        justifyContent: "space-around",
        alignItems: "flex-end",
        padding: "10px 8px 28px",
        borderTopLeftRadius: 36,
        borderTopRightRadius: 36,
        boxShadow: "0 -8px 40px rgba(0, 105, 72, 0.08)",
        zIndex: 60,
      }}
    >
      {items.map(it => {
        const isActive = active === it.key;
        if (it.key === "nuevo") {
          return (
            <button
              key={it.key}
              onClick={() => onNav("nuevo")}
              className="flex flex-col items-center"
              style={{ marginTop: -28, flex: 1 }}
            >
              <div
                className="organic-gradient flex items-center justify-center"
                style={{
                  width: 56, height: 56, borderRadius: 9999,
                  boxShadow: "var(--shadow-fab)",
                  color: "#fff",
                }}
              >
                <Icon name="add" className="text-[32px]" />
              </div>
              <span className="text-[9px] font-black uppercase tracking-widest mt-1" style={{ color: "var(--primary)" }}>
                {it.label}
              </span>
            </button>
          );
        }
        return (
          <button
            key={it.key}
            onClick={() => onNav(it.key)}
            className="flex flex-col items-center py-2"
            style={{
              flex: 1,
              color: isActive ? "var(--primary)" : "var(--outline)",
            }}
          >
            <div className="relative">
              <Icon name={it.icon} fill={isActive} />
              {it.badge && (
                <span
                  style={{
                    position: "absolute",
                    top: -4, right: -8,
                    background: "#dc2626",
                    color: "#fff",
                    borderRadius: 9999,
                    fontSize: 9,
                    fontWeight: 900,
                    width: 16, height: 16,
                    display: "flex", alignItems: "center", justifyContent: "center",
                    border: "2px solid var(--surface)",
                  }}
                >{it.badge}</span>
              )}
            </div>
            <span className="text-[9px] font-black uppercase tracking-widest mt-1">{it.label}</span>
          </button>
        );
      })}
    </nav>
  );
}

// ------------ Top section segmented tabs (Monitoreo/Agenda/Evento) ------------
function SegTabs({ tabs, active, onChange }) {
  return (
    <div
      className="bg-sc-low"
      style={{ borderRadius: 9999, padding: 4, display: "flex", gap: 4 }}
    >
      {tabs.map(t => (
        <button
          key={t}
          onClick={() => onChange && onChange(t)}
          className="flex-1 text-center font-bold"
          style={{
            padding: "8px 12px",
            borderRadius: 9999,
            fontSize: 13,
            background: active === t ? "var(--surface-container-lowest)" : "transparent",
            color: active === t ? "var(--primary)" : "var(--on-surface-variant)",
            boxShadow: active === t ? "0 2px 8px rgba(0,105,72,0.08)" : "none",
            transition: "all .2s ease",
          }}
        >
          {t}
        </button>
      ))}
    </div>
  );
}

// ------------ Section header (kicker) ------------
function Kicker({ children, action }) {
  return (
    <div className="flex items-center justify-between mb-3 px-1">
      <h3 className="text-[11px] font-extrabold uppercase tracking-[0.12em] text-on-surface-variant">{children}</h3>
      {action}
    </div>
  );
}

// ------------ Pill chip ------------
function Chip({ children, tone = "primary", size = "md" }) {
  const styles = {
    primary: { bg: "color-mix(in oklab, var(--primary) 12%, transparent)", fg: "var(--primary)" },
    tertiary: { bg: "color-mix(in oklab, var(--tertiary) 12%, transparent)", fg: "var(--tertiary)" },
    emerald: { bg: "color-mix(in oklab, var(--primary-fixed-dim) 22%, transparent)", fg: "var(--primary)" },
    slate: { bg: "var(--surface-container)", fg: "var(--on-surface-variant)" },
    error: { bg: "var(--error-container)", fg: "var(--on-error-container)" },
    warning: { bg: "color-mix(in oklab, var(--warning) 18%, transparent)", fg: "var(--warning)" },
  };
  const s = styles[tone] || styles.primary;
  const sizes = {
    sm: { padding: "3px 8px", fontSize: 9 },
    md: { padding: "4px 10px", fontSize: 10 },
  };
  return (
    <span
      style={{
        background: s.bg,
        color: s.fg,
        borderRadius: 9999,
        fontWeight: 900,
        textTransform: "uppercase",
        letterSpacing: "0.12em",
        whiteSpace: "nowrap",
        ...sizes[size],
      }}
    >{children}</span>
  );
}

// ------------ Status bar (iOS-style faux) ------------
function StatusBar() {
  return (
    <div className="status-bar">
      <span>9:41</span>
      <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13 }}>
        <Icon name="signal_cellular_4_bar" className="text-[14px]" />
        <Icon name="wifi" className="text-[14px]" />
        <Icon name="battery_full" className="text-[14px]" />
      </div>
    </div>
  );
}

// ------------ Field row (settings list) ------------
function ListRow({ icon, iconBg, iconColor, title, subtitle, trailing, onClick }) {
  return (
    <button
      onClick={onClick}
      className="w-full flex items-center gap-4 py-4 px-2 text-left"
      style={{ minHeight: 56 }}
    >
      <div
        className="flex items-center justify-center"
        style={{
          width: 44, height: 44, borderRadius: 9999,
          background: iconBg || "color-mix(in oklab, var(--primary) 12%, transparent)",
          color: iconColor || "var(--primary)", flexShrink: 0,
        }}
      >
        <Icon name={icon} />
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-bold text-on-surface text-[15px]">{title}</div>
        {subtitle && <div className="text-xs text-on-surface-variant mt-0.5">{subtitle}</div>}
      </div>
      {trailing}
    </button>
  );
}

// ------------ Switch component ------------
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

// ------------ Text input pill ------------
function TextField({ icon, placeholder, type = "text", value, onChange, trailing }) {
  return (
    <div
      className="relative flex items-center bg-sc-low"
      style={{ borderRadius: 9999, height: 52, paddingLeft: icon ? 48 : 20, paddingRight: 16 }}
    >
      {icon && (
        <Icon name={icon} className="absolute" style={{ left: 18, top: "50%", transform: "translateY(-50%)", color: "var(--outline)" }} />
      )}
      <input
        className="bg-transparent outline-none flex-1 text-[15px] text-on-surface placeholder:text-outline"
        placeholder={placeholder}
        type={type}
        value={value || ""}
        onChange={onChange || (() => {})}
        style={{ width: "100%" }}
      />
      {trailing}
    </div>
  );
}

// ------------ Label cap ------------
function Cap({ children, action, className = "" }) {
  return (
    <div className={"flex justify-between items-center px-4 " + className}>
      <label className="text-[10px] font-extrabold tracking-[0.15em] uppercase text-outline">{children}</label>
      {action}
    </div>
  );
}

Object.assign(window, { Icon, Avatar, Photo, TopBar, BottomNav, SegTabs, Kicker, Chip, StatusBar, ListRow, Switch, TextField, Cap });
