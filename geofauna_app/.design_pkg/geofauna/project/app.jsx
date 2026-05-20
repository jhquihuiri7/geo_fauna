/* Main app shell — sidebar with all screens, dark/light toggle, phone viewport */
const SCREENS = [
  { key: "login",     label: "Iniciar Sesión",            section: "Autenticación", icon: "login" },
  { key: "signup",    label: "Registro de Usuario",       section: "Autenticación", icon: "person_add" },
  { key: "dashboard", label: "Inicio · Dashboard",        section: "Núcleo",        icon: "dashboard" },
  { key: "agenda",    label: "Agenda · Bitácora",         section: "Núcleo",        icon: "event_note" },
  { key: "muro",      label: "Muro de Comunidad",         section: "Núcleo",        icon: "forum" },
  { key: "perfil",    label: "Perfil · Mi Bitácora",      section: "Núcleo",        icon: "person" },
  { key: "nuevo:campo",  label: "Nuevo Registro de Campo",   section: "Captura",   icon: "add_a_photo" },
  { key: "nuevo:tour",   label: "Nuevo Registro de Tour",    section: "Captura",   icon: "explore" },
  { key: "nuevo:evento", label: "Crear Evento",              section: "Captura",   icon: "rocket_launch" },
  { key: "reporte",     label: "Reporte de Impacto",         section: "Análisis",  icon: "monitoring" },
  { key: "integridad",  label: "Protocolo de Integridad",    section: "Sistema",   icon: "shield" },
  { key: "settings",    label: "Configuración de Cuenta",    section: "Sistema",   icon: "settings" },
];

function ScreenRouter({ active, onNav, theme, setTheme }) {
  // The active key can be "nuevo:campo" / "nuevo:tour" / "nuevo:evento"
  const [main, sub] = active.split(":");

  if (main === "login")      return <LoginScreen onNav={onNav} />;
  if (main === "signup")     return <SignupScreen onNav={onNav} />;
  if (main === "dashboard")  return <DashboardScreen onNav={onNav} />;
  if (main === "agenda")     return <AgendaScreen onNav={onNav} />;
  if (main === "muro")       return <MuroScreen onNav={onNav} />;
  if (main === "perfil")     return <PerfilScreen onNav={onNav} />;
  if (main === "nuevo")      return <NuevoHubScreen onNav={onNav} subScreen={sub || "campo"} />;
  if (main === "reporte")    return <ReporteScreen onNav={onNav} />;
  if (main === "integridad") return <IntegridadScreen onNav={onNav} />;
  if (main === "settings")   return <SettingsScreen onNav={onNav} theme={theme} setTheme={setTheme} />;
  return <LoginScreen onNav={onNav} />;
}

function PhoneFrame({ children, active, onNav }) {
  const showNav = !["login", "signup"].includes(active.split(":")[0]);
  // Map active screen to bottom-nav highlight
  const navMap = {
    "dashboard": "dashboard",
    "agenda": "agenda",
    "muro": "muro",
    "perfil": "perfil",
    "nuevo:campo": "nuevo",
    "nuevo:tour": "nuevo",
    "nuevo:evento": "nuevo",
    "settings": "perfil",
    "integridad": "perfil",
    "reporte": "dashboard",
  };
  return (
    <div className="phone" data-screen-label={active}>
      <div className="phone-notch" />
      <div className="phone-screen">
        <StatusBar />
        {children}
        {showNav && (
          <BottomNav active={navMap[active] || "dashboard"} onNav={k => {
            if (k === "nuevo") onNav("nuevo:campo");
            else onNav(k);
          }} />
        )}
      </div>
    </div>
  );
}

function Sidebar({ active, onNav }) {
  const grouped = SCREENS.reduce((acc, s) => {
    acc[s.section] = acc[s.section] || [];
    acc[s.section].push(s);
    return acc;
  }, {});
  return (
    <aside style={{
      width: 304,
      background: "var(--surface-container-low)",
      borderRight: "1px solid color-mix(in oklab, var(--outline-variant) 30%, transparent)",
      padding: "28px 18px",
      overflowY: "auto",
      flexShrink: 0,
      height: "100vh",
      position: "sticky",
      top: 0,
    }} className="thin-scroll">
      <div className="flex items-center gap-3 px-2 mb-8">
        <div className="organic-gradient flex items-center justify-center" style={{ width: 44, height: 44, borderRadius: 14 }}>
          <Icon name="eco" fill className="text-[24px]" style={{ color: "#fff" }} />
        </div>
        <div>
          <div className="text-base font-black text-on-surface tracking-tight leading-none">EcoGuía</div>
          <div className="text-[9px] font-extrabold tracking-[0.18em] uppercase text-on-surface-variant mt-1">Galápagos · v2.4</div>
        </div>
      </div>

      {Object.entries(grouped).map(([section, items]) => (
        <div key={section} className="mb-6">
          <div className="text-[9px] font-extrabold tracking-[0.18em] uppercase text-outline px-3 mb-2">{section}</div>
          <div className="space-y-1">
            {items.map(it => {
              const isActive = active === it.key;
              return (
                <button
                  key={it.key}
                  onClick={() => onNav(it.key)}
                  className="w-full flex items-center gap-3 text-left"
                  style={{
                    padding: "10px 12px",
                    borderRadius: 16,
                    background: isActive ? "var(--surface-container-lowest)" : "transparent",
                    color: isActive ? "var(--primary)" : "var(--on-surface)",
                    boxShadow: isActive ? "var(--shadow-card)" : "none",
                    fontWeight: isActive ? 800 : 600,
                    fontSize: 13,
                    transition: "all .15s ease",
                  }}
                >
                  <Icon name={it.icon} fill={isActive} className="text-[18px]" />
                  <span className="truncate">{it.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      ))}
    </aside>
  );
}

function App() {
  const [active, setActive] = useState("dashboard");
  const [theme, setTheme] = useState(() => localStorage.getItem("ecoguia-theme") || "light");

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem("ecoguia-theme", theme);
  }, [theme]);

  const onNav = (key) => setActive(key);

  return (
    <div style={{ display: "flex", minHeight: "100vh", background: "var(--bg)" }}>
      <Sidebar active={active} onNav={onNav} />

      <main style={{
        flex: 1,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        padding: "40px 24px 80px",
        position: "relative",
      }}>
        {/* Top control bar */}
        <div style={{
          width: "100%",
          maxWidth: 1000,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          marginBottom: 28,
        }}>
          <div>
            <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant">EcoGuía Galápagos · Pantallas</div>
            <h1 className="text-3xl font-black tracking-tighter text-on-surface mt-1">
              {(SCREENS.find(s => s.key === active) || {}).label}
            </h1>
          </div>

          <div className="bg-sc-lowest shadow-card flex items-center gap-1" style={{ borderRadius: 9999, padding: 4 }}>
            <button
              onClick={() => setTheme("light")}
              className="flex items-center gap-2"
              style={{
                padding: "8px 16px", borderRadius: 9999,
                background: theme === "light" ? "var(--primary)" : "transparent",
                color: theme === "light" ? "#fff" : "var(--on-surface)",
                fontWeight: 800, fontSize: 12,
              }}>
              <Icon name="light_mode" className="text-[16px]" /> Light
            </button>
            <button
              onClick={() => setTheme("dark")}
              className="flex items-center gap-2"
              style={{
                padding: "8px 16px", borderRadius: 9999,
                background: theme === "dark" ? "var(--primary)" : "transparent",
                color: theme === "dark" ? "var(--on-primary)" : "var(--on-surface)",
                fontWeight: 800, fontSize: 12,
              }}>
              <Icon name="dark_mode" className="text-[16px]" /> Dark
            </button>
          </div>
        </div>

        {/* Phone */}
        <PhoneFrame active={active} onNav={onNav}>
          <ScreenRouter active={active} onNav={onNav} theme={theme} setTheme={setTheme} />
        </PhoneFrame>

        <p className="text-on-surface-variant text-xs mt-6" style={{ opacity: 0.7 }}>
          Toca el bottom-nav para navegar entre pantallas principales · usa la barra lateral para saltar a cualquier pantalla
        </p>
      </main>
    </div>
  );
}

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<App />);
