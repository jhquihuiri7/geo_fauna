/* Canvas layout — all 12 screens in light and dark, side by side */

const SCREEN_SPECS = [
  { key: "login",         label: "01 · Iniciar Sesión",       height: 900,  Comp: () => <LoginScreen onNav={() => {}} />,        bottomNav: false },
  { key: "signup",        label: "02 · Registro",             height: 1180, Comp: () => <SignupScreen onNav={() => {}} />,       bottomNav: false },
  { key: "dashboard",     label: "03 · Inicio · Dashboard",   height: 1880, Comp: () => <DashboardScreen onNav={() => {}} />,    bottomNav: "dashboard" },
  { key: "agenda",        label: "04 · Agenda · Bitácora",    height: 1180, Comp: () => <AgendaScreen onNav={() => {}} />,       bottomNav: "agenda" },
  { key: "muro",          label: "05 · Muro Comunidad",       height: 1480, Comp: () => <MuroScreen onNav={() => {}} />,         bottomNav: "muro" },
  { key: "perfil",        label: "06 · Perfil · Mi Bitácora", height: 1620, Comp: () => <PerfilScreen onNav={() => {}} />,       bottomNav: "perfil" },
  { key: "nuevo-campo",   label: "07 · Nuevo Registro Campo", height: 1640, Comp: () => <NuevoHubScreen onNav={() => {}} subScreen="campo" />,   bottomNav: "nuevo" },
  { key: "nuevo-tour",    label: "08 · Registro de Tour",     height: 1320, Comp: () => <NuevoHubScreen onNav={() => {}} subScreen="tour" />,    bottomNav: "nuevo" },
  { key: "nuevo-evento",  label: "09 · Crear Evento",         height: 2020, Comp: () => <NuevoHubScreen onNav={() => {}} subScreen="evento" />,  bottomNav: "nuevo" },
  { key: "reporte",       label: "10 · Reporte de Impacto",   height: 1820, Comp: () => <ReporteScreen onNav={() => {}} />,      bottomNav: "dashboard" },
  { key: "integridad",    label: "11 · Protocolo Integridad", height: 1380, Comp: () => <IntegridadScreen onNav={() => {}} />,   bottomNav: "perfil" },
  { key: "settings",      label: "12 · Configuración",        height: 1480, Comp: () => <SettingsScreen onNav={() => {}} theme="light" setTheme={() => {}} />, bottomNav: "perfil" },
];

function ScreenFrame({ spec, theme }) {
  return (
    <div
      data-theme={theme}
      style={{
        width: 390,
        height: spec.height,
        background: "var(--surface)",
        position: "relative",
        overflow: "hidden",
        color: "var(--on-surface)",
        fontFamily: "Inter, sans-serif",
      }}
    >
      <StatusBar />
      <spec.Comp />
      {spec.bottomNav && <BottomNav active={spec.bottomNav} onNav={() => {}} />}
    </div>
  );
}

function CanvasApp() {
  // Disable document-level theme to avoid affecting individual artboards
  useEffect(() => {
    document.documentElement.setAttribute("data-theme", "light");
  }, []);

  return (
    <DesignCanvas>
      <DCSection id="light" title="Light Mode" subtitle="12 pantallas · paleta The Organic Archive">
        {SCREEN_SPECS.map(s => (
          <DCArtboard key={s.key + "-l"} id={s.key + "-l"} label={s.label} width={390} height={s.height}>
            <ScreenFrame spec={s} theme="light" />
          </DCArtboard>
        ))}
      </DCSection>
      <DCSection id="dark" title="Dark Mode" subtitle="Mismas 12 pantallas · tokens invertidos Material 3">
        {SCREEN_SPECS.map(s => (
          <DCArtboard key={s.key + "-d"} id={s.key + "-d"} label={s.label} width={390} height={s.height}>
            <ScreenFrame spec={s} theme="dark" />
          </DCArtboard>
        ))}
      </DCSection>
    </DesignCanvas>
  );
}

const canvasRoot = ReactDOM.createRoot(document.getElementById("root"));
canvasRoot.render(<CanvasApp />);
