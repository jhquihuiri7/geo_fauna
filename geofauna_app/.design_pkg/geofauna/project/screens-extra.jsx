/* Extra: Settings, Integridad, Reporte */

function SettingsScreen({ onNav, theme, setTheme }) {
  const [twoFA, setTwoFA] = useState(true);
  const [pushField, setPushField] = useState(true);
  const [pushWall, setPushWall] = useState(false);

  return (
    <div className="bg-surface min-h-full" style={{ paddingBottom: 120 }}>
      <header className="flex items-center gap-3 px-5 py-4 sticky top-[44px] z-30 bg-surface">
        <button onClick={() => onNav("perfil")} className="text-primary"><Icon name="arrow_back" /></button>
        <span className="text-base font-extrabold text-primary tracking-tight">Configuración de Cuenta</span>
      </header>

      <main className="px-6 space-y-6">
        {/* Profile card */}
        <section className="bg-sc-lowest shadow-card flex flex-col items-center text-center" style={{ borderRadius: 32, padding: "30px 24px" }}>
          <div className="relative">
            <Avatar size={96} tone="forest" emoji="🦫" />
            <div style={{
              position: "absolute", bottom: 2, right: 2, width: 22, height: 22,
              background: "var(--primary)", borderRadius: 9999,
              border: "3px solid var(--surface-container-lowest)",
            }} />
          </div>
          <h2 className="text-2xl font-black mt-4 tracking-tight text-on-surface">Carlos Jaramillo</h2>
          <p className="text-on-surface-variant text-sm mt-1">c.jaramillo@parquegalapagos.gob.ec</p>
          <div className="flex gap-2 mt-3">
            <Chip tone="tertiary">Guardaparque Senior</Chip>
            <Chip tone="emerald">Sector Sur</Chip>
          </div>
        </section>

        <Group title="Perfil Personal">
          <ListRow icon="manage_accounts" title="Editar Información" trailing={<Icon name="chevron_right" className="text-outline" />} />
          <Sep />
          <ListRow icon="badge" title="Identificación Digital" trailing={<Icon name="chevron_right" className="text-outline" />} />
        </Group>

        <Group title="Seguridad">
          <ListRow icon="lock_reset" title="Cambiar Contraseña"
            iconBg="color-mix(in oklab, var(--tertiary) 12%, transparent)"
            iconColor="var(--tertiary)"
            trailing={<Icon name="chevron_right" className="text-outline" />} />
          <Sep />
          <ListRow icon="security" title="Autenticación de dos pasos"
            iconBg="color-mix(in oklab, var(--tertiary) 12%, transparent)"
            iconColor="var(--tertiary)"
            trailing={
              <span className="flex items-center gap-2">
                <span className="text-[10px] font-extrabold uppercase tracking-widest text-primary">Activo</span>
                <Icon name="chevron_right" className="text-outline" />
              </span>
            } />
        </Group>

        <Group title="Notificaciones">
          <ListRow icon="notifications_active" title="Alertas de Campo" subtitle="Especies críticas y clima"
            iconBg="color-mix(in oklab, var(--tertiary) 12%, transparent)"
            iconColor="var(--tertiary)"
            trailing={<Switch on={pushField} onChange={setPushField} />} />
          <Sep />
          <ListRow icon="forum" title="Mensajes del Muro" subtitle="Interacciones con equipo"
            iconBg="color-mix(in oklab, var(--tertiary) 12%, transparent)"
            iconColor="var(--tertiary)"
            trailing={<Switch on={pushWall} onChange={setPushWall} />} />
        </Group>

        <Group title="Preferencias">
          <ListRow icon="dark_mode" title="Modo Oscuro"
            iconBg="var(--surface-container)"
            iconColor="var(--on-surface)"
            trailing={<Switch on={theme === "dark"} onChange={v => setTheme(v ? "dark" : "light")} />} />
          <Sep />
          <ListRow icon="language" title="Idioma"
            iconBg="var(--surface-container)"
            iconColor="var(--on-surface)"
            trailing={
              <span className="flex items-center gap-2">
                <span className="text-sm text-on-surface-variant">Español</span>
                <Icon name="chevron_right" className="text-outline" />
              </span>
            } />
        </Group>

        <button className="w-full bg-error-container text-error flex items-center justify-center gap-2 font-extrabold text-sm tracking-widest uppercase"
          style={{ padding: "18px", borderRadius: 9999 }}>
          <Icon name="logout" /> Cerrar Sesión
        </button>

        <p className="text-center text-[10px] font-extrabold uppercase tracking-[0.18em] text-outline">EcoGuía Galápagos · v2.4.0</p>
      </main>
    </div>
  );
}

function Group({ title, children }) {
  return (
    <section>
      <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant mb-2 px-1">{title}</div>
      <div className="bg-sc-lowest shadow-card overflow-hidden" style={{ borderRadius: 32, padding: "4px 14px" }}>
        {children}
      </div>
    </section>
  );
}
function Sep() {
  return <div style={{ height: 1, background: "var(--surface-container)", margin: "0 0 0 60px" }} />;
}

// ---------- INTEGRIDAD ----------
function IntegridadScreen({ onNav }) {
  return (
    <div className="bg-surface min-h-full" style={{ paddingBottom: 120 }}>
      <header className="flex items-center justify-between gap-3 px-5 py-4 sticky top-[44px] z-30 bg-surface">
        <div className="flex items-center gap-3">
          <button onClick={() => onNav("perfil")} className="text-primary"><Icon name="menu" /></button>
          <span className="text-base font-extrabold text-primary tracking-tight">EcoGuía Protocol</span>
        </div>
        <Avatar size={36} tone="forest" emoji="🦫" />
      </header>

      <main className="px-6 space-y-6">
        <section className="organic-gradient relative overflow-hidden" style={{ borderRadius: 32, padding: 28, color: "#fff" }}>
          <div className="dot-pattern" style={{ position: "absolute", inset: 0, opacity: 0.4 }} />
          <div className="relative">
            <h1 className="text-[28px] font-black tracking-tighter leading-[1.05]">
              Protocolo de<br />Integridad de Datos
            </h1>
            <p className="opacity-90 text-sm mt-3 leading-relaxed">
              Estableciendo el estándar para la recolección de datos ambientales precisos en el archipiélago.
            </p>
          </div>
        </section>

        <section className="space-y-4">
          <div className="flex items-center gap-3">
            <div className="flex items-center justify-center" style={{ width: 44, height: 44, borderRadius: 14, background: "color-mix(in oklab, var(--tertiary) 12%, transparent)" }}>
              <Icon name="shield" className="text-tertiary" />
            </div>
            <h2 className="text-lg font-extrabold text-on-surface">Integridad de datos</h2>
          </div>
          <p className="text-on-surface-variant text-sm leading-relaxed">
            En esta app, cada registro contribuye al monitoreo y conservación del entorno. Para asegurar la calidad de la información:
          </p>

          <div className="space-y-3">
            <ProtocolItem icon="location_on" tone="primary" text="Tus registros incluyen ubicación GPS automática" />
            <ProtocolItem icon="photo_camera" tone="primary" text="Puedes añadir fotos como evidencia" />
            <ProtocolItem icon="rule" tone="primary" text="Los datos se validan comparando registros de otros usuarios" />
            <ProtocolItem icon="trending_up" tone="primary" text="Se analiza la coherencia de la información en el tiempo" />
          </div>

          <div className="organic-gradient-soft" style={{ borderRadius: 24, padding: "16px 20px" }}>
            <p className="text-on-surface text-sm leading-relaxed">
              <span className="text-primary font-extrabold">Esto permite generar datos confiables y útiles</span> para la comunidad, la investigación y la gestión ambiental.
            </p>
          </div>
        </section>

        <section className="space-y-4">
          <div className="flex items-center gap-3">
            <div className="flex items-center justify-center" style={{ width: 44, height: 44, borderRadius: 14, background: "color-mix(in oklab, #f59e0b 16%, transparent)" }}>
              <Icon name="key" style={{ color: "#f59e0b" }} />
            </div>
            <h2 className="text-lg font-extrabold text-on-surface">Uso responsable</h2>
          </div>
          <div className="space-y-3 pl-2">
            <Bullet icon="check_circle" tone="tertiary">Registra información real y verificable</Bullet>
            <Bullet icon="visibility_off" tone="tertiary">Evita compartir ubicaciones sensibles de especies vulnerables</Bullet>
            <Bullet icon="eco" tone="tertiary">Usa la app con fines ambientales y profesionales</Bullet>
          </div>
        </section>

        <section className="bg-sc-low" style={{ borderRadius: 32, padding: "20px 22px" }}>
          <div className="flex items-center gap-3 mb-2">
            <div className="flex items-center justify-center" style={{ width: 40, height: 40, borderRadius: 9999, background: "var(--secondary-container)" }}>
              <span style={{ fontSize: 20 }}>🌱</span>
            </div>
            <h3 className="font-extrabold text-on-surface">Compromiso</h3>
          </div>
          <p className="text-on-surface-variant text-sm leading-relaxed">
            Al usar la app, contribuyes a una red de monitoreo basada en ciencia ciudadana, ayudando a proteger la biodiversidad.
          </p>
        </section>
      </main>
    </div>
  );
}

function ProtocolItem({ icon, tone, text }) {
  return (
    <div className="bg-sc-low flex items-center gap-3" style={{ borderRadius: 24, padding: "14px 16px" }}>
      <div className="flex items-center justify-center" style={{ width: 36, height: 36, borderRadius: 10, background: "color-mix(in oklab, var(--primary) 12%, transparent)" }}>
        <Icon name={icon} className="text-primary text-[20px]" />
      </div>
      <p className="text-sm text-on-surface leading-snug flex-1">{text}</p>
    </div>
  );
}
function Bullet({ icon, tone, children }) {
  return (
    <div className="flex items-start gap-3">
      <Icon name={icon} className="text-tertiary text-[18px] mt-0.5" />
      <span className="text-sm text-on-surface-variant leading-relaxed">{children}</span>
    </div>
  );
}

// ---------- REPORTE ----------
function ReporteScreen({ onNav }) {
  return (
    <div className="bg-surface min-h-full" style={{ paddingBottom: 120 }}>
      <header className="flex items-center justify-between gap-3 px-5 py-4 sticky top-[44px] z-30 bg-surface">
        <div className="flex items-center gap-3">
          <button onClick={() => onNav("dashboard")} className="text-primary"><Icon name="arrow_back" /></button>
          <span className="text-base font-extrabold text-primary tracking-tight">Reporte Detallado de Impacto</span>
        </div>
        <Chip tone="slate" size="sm">Últimos 30 días</Chip>
      </header>

      <main className="px-5 space-y-5">
        <section className="grid grid-cols-2 gap-3">
          <Kpi label="Total Sightings" value="15,402" delta="+4.2%" />
          <Kpi label="Species Recorded" value="87" delta="Stable" deltaTone="tertiary" />
          <Kpi label="Data Precision" value="94.2%" delta="✓" deltaTone="primary" />
          <Kpi label="Area Covered" value="1.2k km²" />
        </section>

        <section className="organic-gradient relative overflow-hidden" style={{ borderRadius: 28, padding: 24, color: "#fff" }}>
          <div className="dot-pattern" style={{ position: "absolute", inset: 0, opacity: 0.3 }} />
          <div className="relative">
            <div className="bg-white/15 inline-flex items-center justify-center mb-3" style={{ width: 48, height: 48, borderRadius: 9999 }}>
              <span style={{ fontSize: 22 }}>🌱</span>
            </div>
            <h3 className="text-xl font-extrabold tracking-tight">Logro de Conservación del Mes</h3>
            <p className="text-sm opacity-90 mt-2 leading-relaxed">
              Reducción del <strong className="font-black">12% en incidentes de basura</strong> en zonas críticas gracias a las nuevas patrullas comunitarias en Bahía Academia.
            </p>
          </div>
        </section>

        <section className="bg-sc-lowest shadow-card" style={{ borderRadius: 28, padding: 20 }}>
          <div className="flex items-center justify-between mb-4">
            <h4 className="text-sm font-extrabold text-on-surface">Tendencia de Avistamientos</h4>
            <Icon name="more_horiz" className="text-outline" />
          </div>
          <div className="relative">
            <div className="flex items-end justify-around gap-3" style={{ height: 130 }}>
              {[
                { h: 50, label: "SEM 01" },
                { h: 70, label: "SEM 02" },
                { h: 60, label: "SEM 03", highlight: true, peak: "1.2k" },
                { h: 80, label: "SEM 03" },
                { h: 55, label: "SEM 04" },
              ].map((b, i) => (
                <div key={i} className="flex flex-col items-center" style={{ flex: 1 }}>
                  <div style={{ height: 130 - b.h * 0.6, display: "flex", alignItems: "flex-end", marginBottom: 8 }}>
                    {b.peak && (
                      <span className="bg-primary text-on-primary text-[10px] font-black px-2 py-0.5" style={{ borderRadius: 9999 }}>
                        {b.peak}
                      </span>
                    )}
                  </div>
                  <div className={b.highlight ? "bar-fill" : "bar-fade"} style={{ width: "100%", height: b.h, borderRadius: "12px 12px 0 0" }} />
                  <span className="text-[9px] font-extrabold uppercase tracking-widest text-outline mt-2">{b.label}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="bg-sc-lowest shadow-card" style={{ borderRadius: 28, padding: 20 }}>
          <h4 className="text-sm font-extrabold text-on-surface text-center mb-4">Distribución de Hallazgos</h4>
          <div className="flex items-center justify-center mb-4">
            <DonutChart />
          </div>
          <div className="space-y-2.5">
            <LegendRow color="var(--primary)" label="Fauna" value="60%" />
            <LegendRow color="var(--tertiary)" label="Flora" value="25%" />
            <LegendRow color="#dc2626" label="Incidentes" value="15%" />
          </div>
        </section>

        <section className="bg-sc-lowest shadow-card" style={{ borderRadius: 28, padding: 20 }}>
          <h4 className="text-sm font-extrabold text-on-surface mb-4">Especies con Mayor Impacto</h4>
          <div className="space-y-4">
            <SpeciesRow name="Tortuga Gigante" emoji="🐢" pts="4,820" pct={95} tone="primary" />
            <SpeciesRow name="Iguana Marina" emoji="🦎" pts="3,510" pct={70} tone="emerald" />
            <SpeciesRow name="Piquero Patas Azules" emoji="🐦" pts="2,105" pct={42} tone="tertiary" />
            <SpeciesRow name="Lobo Marino" emoji="🦭" pts="1,920" pct={38} tone="warning" />
          </div>
        </section>

        <section>
          <h4 className="text-sm font-extrabold text-on-surface mb-3 px-1">Actividad por Zonas</h4>
          <div className="space-y-3">
            <ZoneRow name="Santa Cruz" visits="6.2k" incidents="12" status="Alta" />
            <ZoneRow name="Isabela" visits="4.8k" incidents="08" status="Media" tone="tertiary" />
            <ZoneRow name="San Cristóbal" visits="3.4k" incidents="05" status="Estable" tone="emerald" />
          </div>
        </section>
      </main>
    </div>
  );
}

function Kpi({ label, value, delta, deltaTone = "primary" }) {
  return (
    <div className="bg-sc-lowest shadow-card" style={{ borderRadius: 24, padding: "16px 18px" }}>
      <div className="text-[10px] font-extrabold uppercase tracking-widest text-on-surface-variant">{label}</div>
      <div className="text-2xl font-black tracking-tighter text-on-surface mt-2">{value}</div>
      {delta && (
        <div className="text-[11px] font-extrabold mt-1" style={{ color: deltaTone === "tertiary" ? "var(--tertiary)" : "var(--primary)" }}>{delta}</div>
      )}
    </div>
  );
}

function DonutChart() {
  // 60/25/15
  const r = 50, c = 2 * Math.PI * r;
  const segs = [
    { color: "var(--primary)", pct: 60 },
    { color: "var(--tertiary)", pct: 25 },
    { color: "#dc2626", pct: 15 },
  ];
  let offset = 0;
  return (
    <svg width={170} height={170} viewBox="0 0 140 140">
      <circle cx="70" cy="70" r={r} stroke="var(--surface-container-high)" strokeWidth="18" fill="none" />
      {segs.map((s, i) => {
        const len = (s.pct / 100) * c;
        const dash = `${len} ${c - len}`;
        const dashoffset = -offset;
        offset += len;
        return (
          <circle key={i} cx="70" cy="70" r={r} stroke={s.color} strokeWidth="18" fill="none"
            strokeDasharray={dash} strokeDashoffset={dashoffset}
            transform="rotate(-90 70 70)" strokeLinecap="butt" />
        );
      })}
      <text x="70" y="68" textAnchor="middle" fontSize="20" fontWeight="900" fill="var(--on-surface)">15.4k</text>
      <text x="70" y="86" textAnchor="middle" fontSize="9" fontWeight="800" fill="var(--on-surface-variant)" letterSpacing="2">TOTAL</text>
    </svg>
  );
}

function LegendRow({ color, label, value }) {
  return (
    <div className="flex items-center justify-between">
      <span className="flex items-center gap-2 text-sm text-on-surface">
        <span style={{ width: 10, height: 10, borderRadius: 9999, background: color }} />
        {label}
      </span>
      <span className="font-extrabold text-on-surface text-sm">{value}</span>
    </div>
  );
}

function ZoneRow({ name, visits, incidents, status, tone = "warning" }) {
  return (
    <div className="bg-sc-lowest shadow-card flex items-center justify-between" style={{ borderRadius: 24, padding: "14px 18px" }}>
      <div>
        <div className="font-extrabold text-on-surface text-sm">{name}</div>
        <div className="flex items-center gap-3 mt-1 text-on-surface-variant text-[11px]">
          <span className="flex items-center gap-1"><Icon name="visibility" className="text-[13px]" />{visits}</span>
          <span className="flex items-center gap-1"><Icon name="warning" className="text-[13px]" />{incidents}</span>
        </div>
      </div>
      <Chip tone={tone === "tertiary" ? "tertiary" : tone === "emerald" ? "emerald" : "warning"}>{status}</Chip>
    </div>
  );
}

Object.assign(window, { SettingsScreen, IntegridadScreen, ReporteScreen });
