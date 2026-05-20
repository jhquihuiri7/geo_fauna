/* Admin views — all modules */

// ============== DASHBOARD ==============
function AdminDashboard() {
  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Resumen General · Semana W21"
        title="Panel de Control"
        subtitle="Monitoreo en tiempo real de la comunidad EcoGuía Galápagos"
        actions={
          <>
            <Btn variant="secondary" icon="download" size="md">Exportar CSV</Btn>
            <Btn variant="gradient" icon="auto_awesome" size="md">Generar Reporte Semanal</Btn>
          </>
        }
      />

      {/* KPI grid */}
      <div className="grid grid-cols-4 gap-5">
        <StatCard label="Usuarios Activos" value="1,248" delta="+12.4% vs sem. anterior" icon="group" iconTone="primary" />
        <StatCard label="Avistamientos" value="3,102" delta="+8.7%" icon="visibility" iconTone="tertiary" />
        <StatCard label="Posts del Muro" value="540" delta="+3.1%" icon="forum" iconTone="primary" />
        <StatCard label="Denuncias Abiertas" value="12" delta="-4 vs ayer" deltaTone="primary" icon="report" iconTone="error" />
      </div>

      <div className="grid grid-cols-3 gap-5">
        {/* Chart card spanning 2 */}
        <Card className="col-span-2">
          <div className="flex items-end justify-between mb-4">
            <div>
              <h3 className="font-extrabold text-on-surface tracking-tight">Actividad de la Comunidad</h3>
              <p className="text-xs text-on-surface-variant mt-1">Últimas 12 semanas · interacciones diarias</p>
            </div>
            <div className="flex gap-2">
              <Chip tone="primary">Avistamientos</Chip>
              <Chip tone="tertiary">Confirmaciones</Chip>
              <Chip tone="slate">Posts</Chip>
            </div>
          </div>
          <ActivityChart />
        </Card>

        {/* Donut: roles */}
        <Card>
          <h3 className="font-extrabold text-on-surface tracking-tight mb-1">Composición de Usuarios</h3>
          <p className="text-xs text-on-surface-variant mb-5">Distribución por rol activo</p>
          <RolesDonut />
          <div className="space-y-2.5 mt-5">
            <Legend color="var(--primary)" label="Guías" pct="42%" n="524" />
            <Legend color="var(--tertiary)" label="Visitantes" pct="31%" n="387" />
            <Legend color="#f59e0b" label="Investigadores" pct="14%" n="175" />
            <Legend color="#dc2626" label="Guardaparques" pct="9%" n="112" />
            <Legend color="#a855f7" label="Moderadores" pct="4%" n="50" />
          </div>
        </Card>
      </div>

      {/* Bottom grid */}
      <div className="grid grid-cols-3 gap-5">
        <Card className="col-span-2">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-extrabold text-on-surface tracking-tight">Actividad Reciente</h3>
            <Btn variant="ghost" size="sm" iconRight="arrow_forward">Ver auditoría</Btn>
          </div>
          <div className="space-y-1">
            <ActivityRow tone="primary" icon="add_a_photo" who="Martín Solís" what="creó avistamiento" target="Albatros Juvenil" meta="Isla Española · hace 12 min" />
            <ActivityRow tone="tertiary" icon="verified" who="Dra. Elena Ruiz" what="validó como experto" target="Iguana Marina (Sofía M.)" meta="Bahía Tortuga · hace 28 min" />
            <ActivityRow tone="error" icon="flag" who="Anónimo" what="reportó post" target="Especies invasoras (José T.)" meta="hace 1 h · prioridad media" />
            <ActivityRow tone="primary" icon="event_available" who="Carlos Jaramillo" what="creó evento" target="Limpieza Tortuga Bay" meta="28 Oct · 30 cupos" />
            <ActivityRow tone="tertiary" icon="rule" who="Dra. Elena Ruiz" what="propuso corrección" target="Especie en registro #4821" meta="hace 2 h" />
            <ActivityRow tone="primary" icon="route" who="Patricia Soto" what="completó ruta" target="Seymour Norte · 4.8 km" meta="hace 3 h" />
          </div>
        </Card>

        <Card>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-extrabold text-on-surface tracking-tight">Alertas del Sistema</h3>
            <Chip tone="warning">3 nuevas</Chip>
          </div>
          <div className="space-y-3">
            <AlertItem tone="error" icon="error" title="Pico de denuncias" body="Aumento del 40% en reportes de información falsa en las últimas 6 horas" />
            <AlertItem tone="warning" icon="warning" title="Mapas offline" body="Versión 4.2 del paquete Galápagos disponible (124 MB)" />
            <AlertItem tone="primary" icon="check_circle" title="Reporte semanal" body="W21 generado y publicado para todos los administradores" />
          </div>
        </Card>
      </div>
    </div>
  );
}

function PageHeader({ eyebrow, title, subtitle, actions }) {
  return (
    <header className="flex items-end justify-between gap-6">
      <div>
        {eyebrow && <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-primary mb-2">{eyebrow}</div>}
        <h1 className="text-4xl font-black tracking-tighter text-on-surface leading-none">{title}</h1>
        {subtitle && <p className="text-on-surface-variant mt-2 text-[15px]">{subtitle}</p>}
      </div>
      <div className="flex items-center gap-3 flex-shrink-0">{actions}</div>
    </header>
  );
}

function ActivityChart() {
  const series1 = [40, 55, 48, 62, 70, 58, 75, 82, 70, 85, 92, 105];
  const series2 = [22, 30, 28, 38, 42, 36, 50, 56, 48, 62, 68, 80];
  const series3 = [60, 70, 65, 78, 88, 75, 95, 102, 90, 110, 118, 130];

  const W = 720, H = 220, P = 30;
  const max = Math.max(...series3) * 1.1;
  const xs = i => P + (i / (series1.length - 1)) * (W - 2 * P);
  const ys = v => H - P - (v / max) * (H - 2 * P);
  const path = arr => "M " + arr.map((v, i) => `${xs(i)} ${ys(v)}`).join(" L ");
  const area = arr => path(arr) + ` L ${xs(arr.length - 1)} ${H - P} L ${xs(0)} ${H - P} Z`;

  return (
    <svg viewBox={`0 0 ${W} ${H}`} style={{ width: "100%", height: 220 }}>
      <defs>
        <linearGradient id="g1" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor="var(--primary)" stopOpacity="0.4" />
          <stop offset="100%" stopColor="var(--primary)" stopOpacity="0" />
        </linearGradient>
        <linearGradient id="g2" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0%" stopColor="var(--tertiary)" stopOpacity="0.3" />
          <stop offset="100%" stopColor="var(--tertiary)" stopOpacity="0" />
        </linearGradient>
      </defs>
      {/* gridlines */}
      {[0.25, 0.5, 0.75].map(t => (
        <line key={t} x1={P} x2={W - P} y1={H - P - t * (H - 2 * P)} y2={H - P - t * (H - 2 * P)}
          stroke="var(--surface-container-high)" strokeDasharray="3 4" />
      ))}
      <path d={area(series3)} fill="url(#g1)" />
      <path d={path(series3)} fill="none" stroke="var(--primary)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
      <path d={area(series1)} fill="url(#g2)" />
      <path d={path(series1)} fill="none" stroke="var(--tertiary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
      <path d={path(series2)} fill="none" stroke="var(--on-surface-variant)" strokeWidth="1.5" strokeOpacity="0.6" strokeDasharray="4 4" strokeLinecap="round" />
      {["S40","S41","S42","S43","S44","S45","S46","S47","S48","S49","S50","S51"].map((l, i) => (
        <text key={l} x={xs(i)} y={H - 8} textAnchor="middle" fontSize="10" fontWeight="700" fill="var(--outline)">{l}</text>
      ))}
    </svg>
  );
}

function RolesDonut() {
  const data = [
    { color: "var(--primary)", pct: 42 },
    { color: "var(--tertiary)", pct: 31 },
    { color: "#f59e0b", pct: 14 },
    { color: "#dc2626", pct: 9 },
    { color: "#a855f7", pct: 4 },
  ];
  const r = 60, c = 2 * Math.PI * r;
  let offset = 0;
  return (
    <div className="flex justify-center">
      <svg width={180} height={180} viewBox="0 0 180 180">
        <circle cx="90" cy="90" r={r} stroke="var(--surface-container-high)" strokeWidth="20" fill="none" />
        {data.map((s, i) => {
          const len = (s.pct / 100) * c;
          const dash = `${len} ${c - len}`;
          const dashoffset = -offset;
          offset += len;
          return (
            <circle key={i} cx="90" cy="90" r={r} stroke={s.color} strokeWidth="20" fill="none"
              strokeDasharray={dash} strokeDashoffset={dashoffset}
              transform="rotate(-90 90 90)" />
          );
        })}
        <text x="90" y="88" textAnchor="middle" fontSize="28" fontWeight="900" fill="var(--on-surface)" letterSpacing="-1">1,248</text>
        <text x="90" y="108" textAnchor="middle" fontSize="9" fontWeight="800" fill="var(--on-surface-variant)" letterSpacing="2">USUARIOS ACTIVOS</text>
      </svg>
    </div>
  );
}

function Legend({ color, label, pct, n }) {
  return (
    <div className="flex items-center justify-between">
      <span className="flex items-center gap-2.5 text-sm text-on-surface">
        <span style={{ width: 10, height: 10, borderRadius: 9999, background: color }} />
        {label}
      </span>
      <span className="flex items-center gap-3 text-xs">
        <span className="font-extrabold text-on-surface">{pct}</span>
        <span className="text-on-surface-variant">{n}</span>
      </span>
    </div>
  );
}

function ActivityRow({ tone, icon, who, what, target, meta }) {
  const tones = {
    primary: { bg: "color-mix(in oklab, var(--primary) 12%, transparent)", fg: "var(--primary)" },
    tertiary: { bg: "color-mix(in oklab, var(--tertiary) 12%, transparent)", fg: "var(--tertiary)" },
    error: { bg: "var(--error-container)", fg: "var(--error)" },
  };
  const t = tones[tone] || tones.primary;
  return (
    <div className="flex items-center gap-4 py-3" style={{ borderBottom: "1px solid var(--surface-container)" }}>
      <div className="flex items-center justify-center" style={{ width: 36, height: 36, borderRadius: 12, background: t.bg, color: t.fg, flexShrink: 0 }}>
        <Icon name={icon} className="text-[18px]" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-sm text-on-surface">
          <strong className="font-extrabold">{who}</strong>{" "}
          <span className="text-on-surface-variant">{what}</span>{" "}
          <strong className="font-bold">{target}</strong>
        </div>
        <div className="text-[11px] text-outline mt-0.5">{meta}</div>
      </div>
      <button className="text-outline">
        <Icon name="more_horiz" className="text-[18px]" />
      </button>
    </div>
  );
}

function AlertItem({ tone, icon, title, body }) {
  const tones = {
    primary: { bg: "color-mix(in oklab, var(--primary) 10%, transparent)", fg: "var(--primary)" },
    warning: { bg: "color-mix(in oklab, var(--warning) 14%, transparent)", fg: "var(--warning)" },
    error: { bg: "var(--error-container)", fg: "var(--error)" },
  };
  const t = tones[tone] || tones.primary;
  return (
    <div className="flex items-start gap-3" style={{ background: t.bg, borderRadius: 18, padding: "12px 14px" }}>
      <Icon name={icon} className="text-[20px] mt-0.5" style={{ color: t.fg }} />
      <div>
        <div className="font-extrabold text-on-surface text-sm">{title}</div>
        <div className="text-xs text-on-surface-variant mt-1 leading-relaxed">{body}</div>
      </div>
    </div>
  );
}

// ============== USUARIOS ==============
function AdminUsuarios() {
  const [tab, setTab] = useState("Todos");
  const tabs = ["Todos", "Guías", "Guardaparques", "Investigadores", "Visitantes", "Suspendidos"];
  const rows = [
    { name: "Carlos Jaramillo", email: "c.jaramillo@parquegalapagos.gob.ec", role: "Guardaparque", tone: "primary", status: "Activo", xp: 2400, trust: 96, joined: "2024-03-12", emoji: "🦫", avatarTone: "forest" },
    { name: "Dra. Elena Ruiz", email: "elena.ruiz@galapagos.org", role: "Experto", tone: "tertiary", status: "Activo", xp: 3820, trust: 99, joined: "2023-11-04", emoji: "👩‍🔬", avatarTone: "slate" },
    { name: "Martín Solís", email: "martin.solis@ecoguia.org", role: "Guía", tone: "emerald", status: "Activo", xp: 1240, trust: 88, joined: "2024-06-21", emoji: "🧑‍🌾", avatarTone: "blue" },
    { name: "Sofía Mendoza", email: "sofia.mendoza@ecoguia.org", role: "Guía", tone: "emerald", status: "Activo", xp: 1810, trust: 91, joined: "2024-04-08", emoji: "👩", avatarTone: "coral" },
    { name: "Mateo Lara", email: "mateo.lara@galapagos.org", role: "Investigador", tone: "warning", status: "En revisión", xp: 980, trust: 72, joined: "2024-09-15", emoji: "🧑", avatarTone: "olive" },
    { name: "Patricia Soto", email: "patricia.soto@ecoguia.org", role: "Guía", tone: "emerald", status: "Activo", xp: 645, trust: 84, joined: "2025-01-30", emoji: "👩‍🦰", avatarTone: "rose" },
    { name: "José Torres", email: "jose.torres@visitor.ec", role: "Visitante", tone: "slate", status: "Suspendido", xp: 124, trust: 32, joined: "2025-03-10", emoji: "👨", avatarTone: "slate" },
    { name: "Lucía Vega", email: "lucia.vega@ecoguia.org", role: "Moderador", tone: "rose", status: "Activo", xp: 2950, trust: 97, joined: "2023-08-19", emoji: "👩‍💼", avatarTone: "rose" },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Gestión · 1,248 cuentas"
        title="Usuarios y Roles"
        subtitle="Administra cuentas, roles, permisos y reputación de la comunidad"
        actions={
          <>
            <Btn variant="secondary" icon="filter_list">Filtros</Btn>
            <Btn variant="gradient" icon="person_add">Nuevo Usuario</Btn>
          </>
        }
      />

      <Card style={{ padding: 0 }}>
        <div className="flex items-center justify-between gap-4 p-5" style={{ borderBottom: "1px solid var(--surface-container)" }}>
          <div className="flex gap-1 bg-sc-low" style={{ borderRadius: 9999, padding: 4 }}>
            {tabs.map(t => (
              <button key={t} onClick={() => setTab(t)}
                className="text-xs font-bold"
                style={{
                  padding: "8px 16px", borderRadius: 9999,
                  background: tab === t ? "var(--surface-container-lowest)" : "transparent",
                  color: tab === t ? "var(--primary)" : "var(--on-surface-variant)",
                  boxShadow: tab === t ? "0 2px 8px rgba(0,105,72,0.08)" : "none",
                }}>{t}</button>
            ))}
          </div>
          <SearchBar placeholder="Buscar por nombre, email, ID…" />
        </div>

        <Table>
          <thead>
            <tr>
              <TH w="32"><input type="checkbox" /></TH>
              <TH>Usuario</TH>
              <TH>Rol</TH>
              <TH>Estado</TH>
              <TH align="right">XP</TH>
              <TH align="right">Trust</TH>
              <TH>Registro</TH>
              <TH w="100"></TH>
            </tr>
          </thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={i}>
                <TD><input type="checkbox" /></TD>
                <TD>
                  <div className="flex items-center gap-3">
                    <Avatar size={36} tone={r.avatarTone} emoji={r.emoji} />
                    <div>
                      <div className="font-extrabold text-on-surface">{r.name}</div>
                      <div className="text-[11px] text-on-surface-variant">{r.email}</div>
                    </div>
                  </div>
                </TD>
                <TD><Chip tone={r.tone}>{r.role}</Chip></TD>
                <TD>
                  <span className="flex items-center gap-2 text-xs font-bold" style={{
                    color: r.status === "Suspendido" ? "var(--error)" : r.status === "En revisión" ? "var(--warning)" : "var(--primary)"
                  }}>
                    <span style={{
                      width: 8, height: 8, borderRadius: 99,
                      background: r.status === "Suspendido" ? "var(--error)" : r.status === "En revisión" ? "var(--warning)" : "var(--primary)",
                    }} />
                    {r.status}
                  </span>
                </TD>
                <TD align="right" style={{ fontWeight: 800 }}>{r.xp.toLocaleString()}</TD>
                <TD align="right">
                  <div className="flex items-center justify-end gap-2">
                    <div className="bg-sc" style={{ width: 56, height: 6, borderRadius: 99 }}>
                      <div style={{
                        width: r.trust + "%", height: "100%", borderRadius: 99,
                        background: r.trust >= 85 ? "var(--primary)" : r.trust >= 60 ? "var(--warning)" : "var(--error)",
                      }} />
                    </div>
                    <span className="font-extrabold text-xs">{r.trust}</span>
                  </div>
                </TD>
                <TD style={{ color: "var(--on-surface-variant)", fontSize: 12 }}>{r.joined}</TD>
                <TD>
                  <div className="flex items-center gap-1 justify-end">
                    <button className="bg-sc-low flex items-center justify-center" style={{ width: 32, height: 32, borderRadius: 9999 }}>
                      <Icon name="edit" className="text-[16px] text-on-surface-variant" />
                    </button>
                    <button className="bg-sc-low flex items-center justify-center" style={{ width: 32, height: 32, borderRadius: 9999 }}>
                      <Icon name="more_horiz" className="text-[16px] text-on-surface-variant" />
                    </button>
                  </div>
                </TD>
              </tr>
            ))}
          </tbody>
        </Table>

        <div className="flex items-center justify-between p-4">
          <div className="text-xs text-on-surface-variant">Mostrando 8 de 1,248 usuarios</div>
          <div className="flex items-center gap-1">
            <Btn variant="ghost" size="sm" icon="chevron_left" />
            {[1, 2, 3, "…", 156].map((p, i) => (
              <button key={i} className="flex items-center justify-center font-bold text-xs"
                style={{
                  width: 32, height: 32, borderRadius: 9999,
                  background: p === 1 ? "var(--primary)" : "transparent",
                  color: p === 1 ? "var(--on-primary)" : "var(--on-surface-variant)",
                }}>{p}</button>
            ))}
            <Btn variant="ghost" size="sm" icon="chevron_right" />
          </div>
        </div>
      </Card>
    </div>
  );
}

// ============== MODERACIÓN ==============
function AdminModeracion() {
  const [selected, setSelected] = useState(0);
  const queue = [
    { author: "Martín Solís", role: "Guía", time: "hace 12 min", type: "Avistamiento", priority: "Normal", text: "Albatros juvenil fuera de zona típica. Plumaje impecable.", flag: false, confirms: 2, reports: 0, emoji: "🐦", photoTone: 2, label: "ALBATROS · ESPAÑOLA" },
    { author: "José Torres", role: "Visitante", time: "hace 1h", type: "Comentario", priority: "Alta", text: "Comentario reportado por lenguaje agresivo en post #4821", flag: true, confirms: 0, reports: 4, emoji: "💬", photoTone: 1, label: "TEXTO REPORTADO" },
    { author: "Sofía Mendoza", role: "Guía", time: "hace 2h", type: "Avistamiento", priority: "Normal", text: "Grupo de 14 iguanas marinas en zona inusual del intermareal.", flag: false, confirms: 1, reports: 0, emoji: "🦎", photoTone: 3, label: "IGUANA MARINA" },
    { author: "Mateo Lara", role: "Investigador", time: "hace 3h", type: "Corrección", priority: "Media", text: "Propone corregir especie en registro #4821: Phoebastria → Diomedea", flag: false, confirms: 0, reports: 0, emoji: "📝", photoTone: 1, label: "CORRECCIÓN" },
    { author: "Patricia Soto", role: "Guía", time: "hace 5h", type: "Evento", priority: "Normal", text: "Evento 'Limpieza Tortuga Bay' pendiente de aprobación", flag: false, confirms: 0, reports: 0, emoji: "🌊", photoTone: 2, label: "EVENTO" },
  ];
  const current = queue[selected];

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Cola de revisión · 5 pendientes"
        title="Moderación de Contenido"
        subtitle="Revisa avistamientos, posts y comentarios señalados antes de su publicación"
        actions={
          <>
            <Chip tone="warning" size="lg">1 alta prioridad</Chip>
            <Btn variant="secondary" icon="schedule">Mis pendientes</Btn>
          </>
        }
      />

      <div className="grid grid-cols-5 gap-5" style={{ minHeight: 600 }}>
        {/* Queue */}
        <Card className="col-span-2" style={{ padding: 0, overflow: "hidden" }}>
          <div className="flex items-center justify-between p-4" style={{ borderBottom: "1px solid var(--surface-container)" }}>
            <h3 className="font-extrabold text-on-surface text-sm">Cola de Revisión</h3>
            <Chip tone="emerald">5</Chip>
          </div>
          <div className="thin-scroll" style={{ maxHeight: 640, overflowY: "auto" }}>
            {queue.map((q, i) => (
              <button key={i} onClick={() => setSelected(i)}
                className="w-full text-left p-4 flex gap-3"
                style={{
                  background: selected === i ? "var(--surface-container-low)" : "transparent",
                  borderLeft: selected === i ? "3px solid var(--primary)" : "3px solid transparent",
                  borderBottom: "1px solid var(--surface-container)",
                }}>
                <div className="bg-secondary-container flex items-center justify-center" style={{ width: 44, height: 44, borderRadius: 14, fontSize: 22, flexShrink: 0 }}>
                  {q.emoji}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-extrabold text-on-surface text-sm truncate">{q.author}</span>
                    {q.flag && <Icon name="flag" fill className="text-[16px] text-error" />}
                  </div>
                  <div className="flex items-center gap-2 text-[10px] mt-0.5">
                    <Chip tone={q.priority === "Alta" ? "error" : q.priority === "Media" ? "warning" : "slate"} size="sm">{q.priority}</Chip>
                    <span className="text-on-surface-variant">{q.type} · {q.time}</span>
                  </div>
                  <p className="text-xs text-on-surface-variant mt-2 line-clamp-2">{q.text}</p>
                </div>
              </button>
            ))}
          </div>
        </Card>

        {/* Detail */}
        <Card className="col-span-3">
          <div className="flex items-start justify-between mb-5">
            <div className="flex items-center gap-3">
              <Avatar size={48} tone="blue" emoji="🧑‍🔬" />
              <div>
                <div className="font-extrabold text-on-surface text-lg tracking-tight">{current.author}</div>
                <div className="text-xs text-on-surface-variant">{current.role} · {current.time}</div>
              </div>
            </div>
            <div className="flex gap-2">
              <Chip tone={current.priority === "Alta" ? "error" : "slate"}>{current.priority}</Chip>
              <Chip tone="primary">{current.type}</Chip>
            </div>
          </div>

          <p className="text-on-surface text-[15px] leading-relaxed mb-4">{current.text}</p>

          <div style={{ borderRadius: 24, overflow: "hidden", marginBottom: 20 }}>
            <div className={"photo-ph " + (current.photoTone === 2 ? "tone-2" : current.photoTone === 3 ? "tone-3" : "")}
              style={{ aspectRatio: "16/9", position: "relative" }}>
              <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 80, opacity: 0.5 }}>
                {current.emoji}
              </div>
              <div className="ph-label">{current.label}</div>
            </div>
          </div>

          {/* Metadata grid */}
          <div className="grid grid-cols-4 gap-3 mb-5">
            <Metric icon="location_on" label="Coordenadas" value="-0.745, -90.318" />
            <Metric icon="straighten" label="Precisión GPS" value="4.8 m" />
            <Metric icon="verified" label="Confirmaciones" value={`${current.confirms} · 8 pts`} />
            <Metric icon="flag" label="Reportes" value={String(current.reports)} tone={current.reports > 0 ? "error" : "primary"} />
          </div>

          {/* Decision */}
          <div className="bg-sc-low" style={{ borderRadius: 20, padding: 16 }}>
            <div className="text-[10px] font-extrabold uppercase tracking-[0.15em] text-on-surface-variant mb-3">Notas de moderación</div>
            <textarea
              className="bg-sc-lowest w-full text-sm text-on-surface placeholder:text-outline outline-none"
              style={{ borderRadius: 16, padding: 12, minHeight: 64, resize: "vertical" }}
              placeholder="Razón de aprobación o rechazo…"
            />
          </div>

          <div className="flex items-center gap-3 mt-5">
            <Btn variant="danger" icon="cancel" size="lg">Rechazar</Btn>
            <Btn variant="secondary" icon="visibility_off" size="lg">Ocultar</Btn>
            <Btn variant="secondary" icon="forward_to_inbox" size="lg">Escalar</Btn>
            <Btn variant="gradient" icon="check_circle" size="lg" className="ml-auto">Aprobar y otorgar XP</Btn>
          </div>
        </Card>
      </div>
    </div>
  );
}

function Metric({ icon, label, value, tone = "primary" }) {
  const colors = {
    primary: "var(--primary)",
    error: "var(--error)",
    warning: "var(--warning)",
  };
  return (
    <div className="bg-sc-low" style={{ borderRadius: 16, padding: "12px 14px" }}>
      <div className="flex items-center gap-1.5">
        <Icon name={icon} className="text-[14px]" style={{ color: colors[tone] }} />
        <span className="text-[9px] font-extrabold uppercase tracking-widest text-on-surface-variant">{label}</span>
      </div>
      <div className="font-extrabold text-on-surface text-sm mt-1.5">{value}</div>
    </div>
  );
}

// ============== DENUNCIAS ==============
function AdminDenuncias() {
  const rows = [
    { id: "R-4821", target: "Post #4821 · Albatros Juvenil", reporter: "Anónimo", reason: "Información falsa", status: "Pendiente", priority: "Alta", time: "hace 14 min" },
    { id: "R-4820", target: "Comentario en #4815", reporter: "Lucía V.", reason: "Lenguaje agresivo", status: "En revisión", priority: "Media", time: "hace 1 h" },
    { id: "R-4819", target: "Avistamiento #4799", reporter: "Mateo L.", reason: "Ubicación dudosa", status: "Pendiente", priority: "Media", time: "hace 2 h" },
    { id: "R-4818", target: "Post #4801 · Iguana", reporter: "Sofía M.", reason: "Foto duplicada", status: "Resuelta", priority: "Baja", time: "hace 4 h" },
    { id: "R-4817", target: "Usuario · José T.", reporter: "Carlos J.", reason: "Spam de comentarios", status: "Resuelta", priority: "Alta", time: "hace 6 h" },
    { id: "R-4816", target: "Post #4790 · Tortuga", reporter: "Patricia S.", reason: "Ubicación sensible", status: "Pendiente", priority: "Alta", time: "hace 8 h" },
    { id: "R-4815", target: "Evento #312 · Limpieza", reporter: "Anónimo", reason: "Información incompleta", status: "Pendiente", priority: "Baja", time: "ayer" },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Integridad · 12 abiertas"
        title="Denuncias y Reportes"
        subtitle="Revisión de denuncias de contenido falso, inapropiado o problemático"
        actions={
          <>
            <Btn variant="secondary" icon="filter_list">Filtros</Btn>
            <Btn variant="secondary" icon="download">Exportar</Btn>
          </>
        }
      />

      <div className="grid grid-cols-4 gap-5">
        <StatCard label="Pendientes" value="12" icon="schedule" iconTone="warning" />
        <StatCard label="En Revisión" value="4" icon="visibility" iconTone="tertiary" />
        <StatCard label="Resueltas hoy" value="8" delta="+3 vs ayer" icon="task_alt" iconTone="primary" />
        <StatCard label="Tiempo medio" value="2.4h" delta="-12% mejor" icon="timer" iconTone="primary" />
      </div>

      <Card style={{ padding: 0 }}>
        <div className="p-5 flex justify-between items-center" style={{ borderBottom: "1px solid var(--surface-container)" }}>
          <h3 className="font-extrabold text-on-surface">Cola de Denuncias</h3>
          <SearchBar placeholder="Buscar por ID, usuario, razón…" />
        </div>
        <Table>
          <thead>
            <tr>
              <TH>ID</TH>
              <TH>Objetivo</TH>
              <TH>Reportado por</TH>
              <TH>Razón</TH>
              <TH>Prioridad</TH>
              <TH>Estado</TH>
              <TH>Hace</TH>
              <TH w="80"></TH>
            </tr>
          </thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={i}>
                <TD style={{ fontFamily: "ui-monospace, monospace", fontSize: 12, color: "var(--outline)" }}>{r.id}</TD>
                <TD style={{ fontWeight: 700 }}>{r.target}</TD>
                <TD style={{ color: "var(--on-surface-variant)" }}>{r.reporter}</TD>
                <TD>{r.reason}</TD>
                <TD><Chip tone={r.priority === "Alta" ? "error" : r.priority === "Media" ? "warning" : "slate"}>{r.priority}</Chip></TD>
                <TD>
                  <Chip tone={r.status === "Resuelta" ? "emerald" : r.status === "En revisión" ? "tertiary" : "warning"}>{r.status}</Chip>
                </TD>
                <TD style={{ color: "var(--on-surface-variant)", fontSize: 12 }}>{r.time}</TD>
                <TD align="right">
                  <Btn variant="secondary" size="sm" iconRight="arrow_forward">Revisar</Btn>
                </TD>
              </tr>
            ))}
          </tbody>
        </Table>
      </Card>
    </div>
  );
}

Object.assign(window, { AdminDashboard, AdminUsuarios, AdminModeracion, AdminDenuncias });
