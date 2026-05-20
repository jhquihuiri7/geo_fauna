/* Admin app shell — sidebar + topbar + page router */

const ADMIN_NAV = [
  { section: "Operación", items: [
    { key: "dashboard",  label: "Dashboard",        icon: "dashboard" },
    { key: "usuarios",   label: "Usuarios y Roles", icon: "group" },
    { key: "moderacion", label: "Moderación",       icon: "fact_check", badge: 5 },
    { key: "denuncias",  label: "Denuncias",        icon: "report",     badge: 12, badgeTone: "error" },
  ]},
  { section: "Contenido", items: [
    { key: "especies", label: "Catálogo de Especies", icon: "eco" },
    { key: "eventos",  label: "Eventos",              icon: "event" },
  ]},
  { section: "Inteligencia", items: [
    { key: "reportes", label: "Reportes Semanales", icon: "monitoring" },
    { key: "config",   label: "Configuración",      icon: "tune" },
  ]},
];

function AdminRouter({ active }) {
  switch (active) {
    case "dashboard": return <AdminDashboard />;
    case "usuarios": return <AdminUsuarios />;
    case "moderacion": return <AdminModeracion />;
    case "denuncias": return <AdminDenuncias />;
    case "especies": return <AdminEspecies />;
    case "eventos": return <AdminEventos />;
    case "reportes": return <AdminReportes />;
    case "config": return <AdminConfig />;
    default: return <AdminDashboard />;
  }
}

function AdminSidebar({ active, onNav }) {
  return (
    <aside style={{
      width: 268,
      background: "var(--surface-container-low)",
      borderRight: "1px solid color-mix(in oklab, var(--outline-variant) 30%, transparent)",
      padding: "24px 16px",
      overflowY: "auto",
      flexShrink: 0,
      height: "100vh",
      position: "sticky",
      top: 0,
    }} className="thin-scroll">
      <div className="flex items-center gap-3 px-2 mb-2">
        <div className="organic-gradient flex items-center justify-center" style={{ width: 42, height: 42, borderRadius: 14 }}>
          <Icon name="eco" fill className="text-[22px]" style={{ color: "#fff" }} />
        </div>
        <div>
          <div className="text-base font-black text-on-surface tracking-tight leading-none">EcoGuía Admin</div>
          <div className="text-[9px] font-extrabold tracking-[0.18em] uppercase text-on-surface-variant mt-1">Galápagos · Next.js</div>
        </div>
      </div>
      <div className="px-2 mt-2 mb-6">
        <span className="inline-flex items-center gap-1.5 text-[10px] font-extrabold tracking-widest uppercase text-on-surface-variant">
          <span style={{ width: 6, height: 6, borderRadius: 99, background: "#22c55e" }} />
          Cloud Functions · OK
        </span>
      </div>

      {ADMIN_NAV.map(group => (
        <div key={group.section} className="mb-5">
          <div className="text-[9px] font-extrabold tracking-[0.18em] uppercase text-outline px-3 mb-2">{group.section}</div>
          <div className="space-y-1">
            {group.items.map(it => {
              const isActive = active === it.key;
              return (
                <button
                  key={it.key}
                  onClick={() => onNav(it.key)}
                  className="w-full flex items-center gap-3 text-left"
                  style={{
                    padding: "10px 12px",
                    borderRadius: 14,
                    background: isActive ? "var(--surface-container-lowest)" : "transparent",
                    color: isActive ? "var(--primary)" : "var(--on-surface)",
                    boxShadow: isActive ? "var(--shadow-card)" : "none",
                    fontWeight: isActive ? 800 : 600,
                    fontSize: 13,
                    transition: "all .15s ease",
                  }}
                >
                  <Icon name={it.icon} fill={isActive} className="text-[18px]" />
                  <span className="flex-1 truncate">{it.label}</span>
                  {it.badge && (
                    <span style={{
                      background: it.badgeTone === "error" ? "var(--error)" : "var(--primary)",
                      color: "#fff",
                      borderRadius: 9999,
                      fontSize: 10,
                      fontWeight: 900,
                      padding: "1px 7px",
                      minWidth: 18,
                      textAlign: "center",
                    }}>{it.badge}</span>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      ))}

      {/* Profile card pinned bottom */}
      <div className="bg-sc-lowest mt-6 flex items-center gap-3" style={{ borderRadius: 18, padding: 12 }}>
        <Avatar size={40} tone="rose" emoji="👩‍💼" />
        <div className="flex-1 min-w-0">
          <div className="text-sm font-extrabold text-on-surface truncate">Lucía Vega</div>
          <div className="text-[11px] text-on-surface-variant">Admin · GNPS-2023</div>
        </div>
        <button className="text-outline">
          <Icon name="more_vert" className="text-[18px]" />
        </button>
      </div>
    </aside>
  );
}

function AdminTopBar({ theme, setTheme, active }) {
  const titles = {
    dashboard: "Dashboard",
    usuarios: "Usuarios",
    moderacion: "Moderación",
    denuncias: "Denuncias",
    especies: "Catálogo de Especies",
    eventos: "Eventos",
    reportes: "Reportes Semanales",
    config: "Configuración",
  };
  return (
    <header
      className="glass sticky top-0 z-30 flex items-center justify-between gap-4"
      style={{
        padding: "14px 32px",
        borderBottom: "1px solid color-mix(in oklab, var(--outline-variant) 30%, transparent)",
      }}
    >
      <div className="flex items-center gap-3 text-sm">
        <Icon name="home" className="text-[16px] text-outline" />
        <span className="text-outline">Admin</span>
        <Icon name="chevron_right" className="text-[14px] text-outline" />
        <span className="font-extrabold text-on-surface">{titles[active]}</span>
      </div>

      <div className="flex items-center gap-3">
        <SearchBar placeholder="Buscar usuarios, posts, especies…" />

        <button className="bg-sc-low flex items-center justify-center relative" style={{ width: 40, height: 40, borderRadius: 9999 }}>
          <Icon name="notifications" className="text-on-surface text-[20px]" />
          <span style={{
            position: "absolute", top: 6, right: 6, width: 8, height: 8,
            background: "var(--error)", borderRadius: 99, border: "2px solid var(--surface-container-low)",
          }} />
        </button>

        <div className="bg-sc-low flex items-center gap-1" style={{ borderRadius: 9999, padding: 3 }}>
          <button
            onClick={() => setTheme("light")}
            className="flex items-center justify-center"
            style={{
              width: 32, height: 32, borderRadius: 9999,
              background: theme === "light" ? "var(--primary)" : "transparent",
              color: theme === "light" ? "#fff" : "var(--on-surface-variant)",
            }}
            aria-label="Light"
          >
            <Icon name="light_mode" className="text-[18px]" />
          </button>
          <button
            onClick={() => setTheme("dark")}
            className="flex items-center justify-center"
            style={{
              width: 32, height: 32, borderRadius: 9999,
              background: theme === "dark" ? "var(--primary)" : "transparent",
              color: theme === "dark" ? "var(--on-primary)" : "var(--on-surface-variant)",
            }}
            aria-label="Dark"
          >
            <Icon name="dark_mode" className="text-[18px]" />
          </button>
        </div>
      </div>
    </header>
  );
}

function AdminApp() {
  const [active, setActive] = useState("dashboard");
  const [theme, setTheme] = useState(() => localStorage.getItem("ecoguia-admin-theme") || "light");

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem("ecoguia-admin-theme", theme);
  }, [theme]);

  return (
    <div style={{ display: "flex", minHeight: "100vh", background: "var(--bg)" }}>
      <AdminSidebar active={active} onNav={setActive} />
      <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column" }}>
        <AdminTopBar theme={theme} setTheme={setTheme} active={active} />
        <main style={{ padding: "32px 32px 64px", maxWidth: 1480, width: "100%", margin: "0 auto" }}>
          <AdminRouter active={active} />
        </main>
      </div>
    </div>
  );
}

const adminRoot = ReactDOM.createRoot(document.getElementById("root"));
adminRoot.render(<AdminApp />);
