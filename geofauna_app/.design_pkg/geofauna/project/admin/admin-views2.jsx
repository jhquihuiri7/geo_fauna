/* Admin views — Especies, Eventos, Reportes, Configuración */

// ============== ESPECIES ==============
function AdminEspecies() {
  const cats = ["Todas", "Fauna", "Flora", "Marinas", "Invasoras"];
  const [cat, setCat] = useState("Todas");
  const species = [
    { common: "Tortuga gigante", sci: "Chelonoidis niger", cat: "Fauna", status: "Vulnerable", count: 4201, emoji: "🐢", tone: 1 },
    { common: "Iguana marina", sci: "Amblyrhynchus cristatus", cat: "Fauna", status: "Vulnerable", count: 3510, emoji: "🦎", tone: 3 },
    { common: "Piquero patas azules", sci: "Sula nebouxii", cat: "Fauna", status: "Estable", count: 2840, emoji: "🐦", tone: 2 },
    { common: "Lobo marino", sci: "Zalophus wollebaeki", cat: "Marinas", status: "En peligro", count: 1950, emoji: "🦭", tone: 3 },
    { common: "Albatros", sci: "Phoebastria irrorata", cat: "Fauna", status: "Crítico", count: 1240, emoji: "🦅", tone: 2 },
    { common: "Manzanillo", sci: "Hippomane mancinella", cat: "Flora", status: "Estable", count: 820, emoji: "🌳", tone: 3 },
    { common: "Cormorán no volador", sci: "Phalacrocorax harrisi", cat: "Fauna", status: "Crítico", count: 540, emoji: "🐧", tone: 2 },
    { common: "Cabra salvaje", sci: "Capra hircus", cat: "Invasoras", status: "Invasiva", count: 410, emoji: "🐐", tone: 1 },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Catálogo · 87 especies"
        title="Catálogo de Especies"
        subtitle="Mantén el catálogo biológico que la app consume offline"
        actions={
          <>
            <Btn variant="secondary" icon="cloud_sync">Sincronizar offline</Btn>
            <Btn variant="gradient" icon="add">Añadir Especie</Btn>
          </>
        }
      />

      <div className="grid grid-cols-4 gap-5">
        <StatCard label="Total catalogadas" value="87" delta="+4 esta semana" icon="eco" iconTone="primary" />
        <StatCard label="En peligro" value="14" icon="warning" iconTone="error" />
        <StatCard label="Invasoras" value="9" icon="dangerous" iconTone="warning" />
        <StatCard label="Endémicas" value="63" icon="public" iconTone="tertiary" />
      </div>

      <Card style={{ padding: 0 }}>
        <div className="p-5 flex items-center justify-between" style={{ borderBottom: "1px solid var(--surface-container)" }}>
          <div className="flex gap-1 bg-sc-low" style={{ borderRadius: 9999, padding: 4 }}>
            {cats.map(t => (
              <button key={t} onClick={() => setCat(t)}
                className="text-xs font-bold"
                style={{
                  padding: "8px 16px", borderRadius: 9999,
                  background: cat === t ? "var(--surface-container-lowest)" : "transparent",
                  color: cat === t ? "var(--primary)" : "var(--on-surface-variant)",
                  boxShadow: cat === t ? "0 2px 8px rgba(0,105,72,0.08)" : "none",
                }}>{t}</button>
            ))}
          </div>
          <SearchBar placeholder="Buscar especie…" />
        </div>

        <div className="p-5 grid grid-cols-4 gap-4">
          {species.map((s, i) => (
            <div key={i} className="bg-sc-low overflow-hidden" style={{ borderRadius: 24 }}>
              <div className={"photo-ph " + (s.tone === 2 ? "tone-2" : s.tone === 3 ? "tone-3" : "")} style={{ aspectRatio: "1/1", position: "relative" }}>
                <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 56, opacity: 0.65 }}>{s.emoji}</div>
                <div style={{ position: "absolute", top: 10, left: 10 }}>
                  <Chip tone={
                    s.status === "Crítico" ? "error" :
                    s.status === "En peligro" ? "error" :
                    s.status === "Vulnerable" ? "warning" :
                    s.status === "Invasiva" ? "rose" : "emerald"
                  }>{s.status}</Chip>
                </div>
              </div>
              <div style={{ padding: 14 }}>
                <div className="font-extrabold text-on-surface text-sm tracking-tight">{s.common}</div>
                <div className="text-[11px] italic text-on-surface-variant mt-0.5">{s.sci}</div>
                <div className="flex items-center justify-between mt-3">
                  <span className="text-[10px] font-extrabold uppercase tracking-widest text-outline">{s.cat}</span>
                  <span className="text-xs font-extrabold text-on-surface flex items-center gap-1">
                    <Icon name="visibility" className="text-[14px] text-primary" />
                    {s.count.toLocaleString()}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

// ============== EVENTOS ==============
function AdminEventos() {
  const rows = [
    { title: "Workshop: Corales", creator: "Dra. Elena Ruiz", date: "24 Oct · 09:00", loc: "Bahía Academia", type: "Taller", cap: 25, reg: 22, wait: 3, status: "Activo" },
    { title: "Limpieza Tortuga Bay", creator: "Carlos Jaramillo", date: "28 Oct · 06:00", loc: "Tortuga Bay", type: "Limpieza", cap: 30, reg: 30, wait: 8, status: "Completo" },
    { title: "Censo de Iguanas", creator: "Mateo Lara", date: "02 Nov · 07:00", loc: "Plaza Sur", type: "Misión", cap: 15, reg: 9, wait: 0, status: "Activo" },
    { title: "Tour Educativo escuelas", creator: "Patricia Soto", date: "05 Nov · 10:00", loc: "Estación Darwin", type: "Educativo", cap: 40, reg: 12, wait: 0, status: "Activo" },
    { title: "Patrullaje nocturno", creator: "Carlos Jaramillo", date: "07 Nov · 21:00", loc: "Punta Cormorant", type: "Misión", cap: 8, reg: 0, wait: 0, status: "Borrador" },
    { title: "Charla Conservación Marina", creator: "Sofía Mendoza", date: "20 Oct · 17:00", loc: "Puerto Ayora", type: "Taller", cap: 60, reg: 58, wait: 4, status: "Pasado" },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Calendario · 18 esta semana"
        title="Gestión de Eventos"
        subtitle="Eventos creados por la comunidad: cupos, lista de espera y asistencia"
        actions={
          <>
            <Btn variant="secondary" icon="calendar_month">Vista calendario</Btn>
            <Btn variant="gradient" icon="add">Nuevo Evento</Btn>
          </>
        }
      />

      <div className="grid grid-cols-4 gap-5">
        <StatCard label="Activos" value="18" icon="event_available" iconTone="primary" />
        <StatCard label="Asistentes esta semana" value="412" delta="+18%" icon="group" iconTone="tertiary" />
        <StatCard label="Lista de espera" value="47" icon="hourglass_top" iconTone="warning" />
        <StatCard label="Tasa asistencia" value="89%" delta="+2.1%" icon="check_circle" iconTone="primary" />
      </div>

      <Card style={{ padding: 0 }}>
        <div className="p-5 flex justify-between items-center" style={{ borderBottom: "1px solid var(--surface-container)" }}>
          <h3 className="font-extrabold text-on-surface">Próximos y recientes</h3>
          <SearchBar placeholder="Buscar evento…" />
        </div>
        <Table>
          <thead>
            <tr>
              <TH>Evento</TH>
              <TH>Tipo</TH>
              <TH>Fecha</TH>
              <TH>Ubicación</TH>
              <TH align="right">Cupos</TH>
              <TH>Estado</TH>
              <TH w="80"></TH>
            </tr>
          </thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={i}>
                <TD>
                  <div className="font-extrabold text-on-surface">{r.title}</div>
                  <div className="text-[11px] text-on-surface-variant mt-0.5">por {r.creator}</div>
                </TD>
                <TD><Chip tone={r.type === "Limpieza" ? "primary" : r.type === "Taller" ? "tertiary" : r.type === "Educativo" ? "rose" : "emerald"}>{r.type}</Chip></TD>
                <TD style={{ fontWeight: 700 }}>{r.date}</TD>
                <TD style={{ color: "var(--on-surface-variant)" }}>{r.loc}</TD>
                <TD align="right">
                  <div className="flex items-center justify-end gap-2">
                    <span className="font-extrabold">{r.reg}/{r.cap}</span>
                    <div className="bg-sc" style={{ width: 56, height: 6, borderRadius: 99 }}>
                      <div style={{
                        width: ((r.reg / r.cap) * 100) + "%", height: "100%", borderRadius: 99,
                        background: r.reg === r.cap ? "var(--warning)" : "var(--primary)",
                      }} />
                    </div>
                    {r.wait > 0 && <Chip tone="slate" size="sm">+{r.wait}</Chip>}
                  </div>
                </TD>
                <TD>
                  <Chip tone={
                    r.status === "Activo" ? "emerald" :
                    r.status === "Completo" ? "warning" :
                    r.status === "Borrador" ? "slate" : "outline"
                  }>{r.status}</Chip>
                </TD>
                <TD align="right">
                  <button className="bg-sc-low flex items-center justify-center" style={{ width: 32, height: 32, borderRadius: 9999 }}>
                    <Icon name="chevron_right" className="text-[16px] text-on-surface-variant" />
                  </button>
                </TD>
              </tr>
            ))}
          </tbody>
        </Table>
      </Card>
    </div>
  );
}

// ============== REPORTES ==============
function AdminReportes() {
  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Inteligencia · W21 · 18-24 Oct 2026"
        title="Reportes Semanales"
        subtitle="Datos generados por Cloud Functions y exportables para investigación"
        actions={
          <>
            <Btn variant="secondary" icon="picture_as_pdf">Exportar PDF</Btn>
            <Btn variant="secondary" icon="table_view">CSV / JSON</Btn>
            <Btn variant="gradient" icon="schedule_send">Programar envío</Btn>
          </>
        }
      />

      <div className="grid grid-cols-4 gap-5">
        <StatCard label="Avistamientos" value="3,102" delta="+8.7%" icon="visibility" iconTone="primary" />
        <StatCard label="Rutas completadas" value="412" delta="+12.1%" icon="route" iconTone="tertiary" />
        <StatCard label="Confirmaciones" value="2,840" delta="+5.4%" icon="verified" iconTone="primary" />
        <StatCard label="Precisión GPS media" value="3.8 m" delta="-0.4m" icon="my_location" iconTone="primary" />
      </div>

      <div className="grid grid-cols-3 gap-5">
        <Card className="col-span-2">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="font-extrabold text-on-surface tracking-tight">Top Especies Reportadas</h3>
              <p className="text-xs text-on-surface-variant mt-1">Ranked por confirmaciones validadas</p>
            </div>
            <Chip tone="emerald">Calidad científica</Chip>
          </div>
          <div className="space-y-4">
            <BarRow emoji="🐢" name="Tortuga Gigante" sci="Chelonoidis niger" pts="4,820" pct={95} />
            <BarRow emoji="🦎" name="Iguana Marina" sci="Amblyrhynchus cristatus" pts="3,510" pct={72} />
            <BarRow emoji="🐦" name="Piquero Patas Azules" sci="Sula nebouxii" pts="2,105" pct={45} />
            <BarRow emoji="🦭" name="Lobo Marino" sci="Zalophus wollebaeki" pts="1,920" pct={40} />
            <BarRow emoji="🦅" name="Albatros" sci="Phoebastria irrorata" pts="1,240" pct={26} />
          </div>
        </Card>

        <Card>
          <h3 className="font-extrabold text-on-surface tracking-tight mb-1">Zonas con Mayor Actividad</h3>
          <p className="text-xs text-on-surface-variant mb-4">Avistamientos por isla esta semana</p>
          <div className="space-y-3">
            <ZoneRow emoji="🏝️" name="Santa Cruz" pct={92} value="2,840" status="Alta" />
            <ZoneRow emoji="🌋" name="Isabela" pct={65} value="1,820" status="Media" tone="tertiary" />
            <ZoneRow emoji="🪸" name="San Cristóbal" pct={42} value="1,210" status="Estable" tone="emerald" />
            <ZoneRow emoji="🦤" name="Española" pct={30} value="780" status="Estable" tone="emerald" />
            <ZoneRow emoji="🌊" name="Floreana" pct={22} value="540" status="Baja" tone="slate" />
          </div>
        </Card>
      </div>

      <Card>
        <div className="flex items-end justify-between mb-4">
          <div>
            <h3 className="font-extrabold text-on-surface tracking-tight">Reportes Programados</h3>
            <p className="text-xs text-on-surface-variant mt-1">Cloud Scheduler · próximas ejecuciones</p>
          </div>
          <Btn variant="secondary" size="sm" icon="add">Nuevo reporte</Btn>
        </div>
        <Table>
          <thead>
            <tr>
              <TH>Nombre</TH>
              <TH>Frecuencia</TH>
              <TH>Próxima ejecución</TH>
              <TH>Destinatarios</TH>
              <TH>Última ejecución</TH>
              <TH>Estado</TH>
              <TH w="80"></TH>
            </tr>
          </thead>
          <tbody>
            {[
              { name: "Reporte semanal admins", freq: "Lun 09:00", next: "27 Oct · 09:00", who: "12 admins", last: "✓ 20 Oct", status: "Activo" },
              { name: "Dataset investigación", freq: "Mensual día 1", next: "1 Nov · 06:00", who: "Dataset público", last: "✓ 1 Oct", status: "Activo" },
              { name: "KPIs comunidad", freq: "Diario 22:00", next: "Hoy · 22:00", who: "Slack #ecoguia", last: "✓ Ayer", status: "Activo" },
              { name: "Ranking semanal", freq: "Dom 23:59", next: "26 Oct · 23:59", who: "Todos los usuarios", last: "✓ 19 Oct", status: "Activo" },
              { name: "Backup auditoría", freq: "Mensual día 28", next: "28 Oct · 03:00", who: "Storage privado", last: "—", status: "Pausa" },
            ].map((r, i) => (
              <tr key={i}>
                <TD style={{ fontWeight: 700 }}>{r.name}</TD>
                <TD style={{ color: "var(--on-surface-variant)" }}>{r.freq}</TD>
                <TD style={{ fontWeight: 700 }}>{r.next}</TD>
                <TD>{r.who}</TD>
                <TD style={{ color: "var(--on-surface-variant)", fontSize: 12 }}>{r.last}</TD>
                <TD><Chip tone={r.status === "Pausa" ? "slate" : "emerald"}>{r.status}</Chip></TD>
                <TD align="right">
                  <Btn variant="ghost" size="sm" icon="more_horiz" />
                </TD>
              </tr>
            ))}
          </tbody>
        </Table>
      </Card>
    </div>
  );
}

function BarRow({ emoji, name, sci, pts, pct }) {
  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-3">
          <div className="bg-secondary-container flex items-center justify-center" style={{ width: 36, height: 36, borderRadius: 12, fontSize: 18 }}>{emoji}</div>
          <div>
            <div className="font-extrabold text-on-surface text-sm">{name}</div>
            <div className="text-[11px] italic text-on-surface-variant">{sci}</div>
          </div>
        </div>
        <span className="font-extrabold text-on-surface text-sm">{pts}</span>
      </div>
      <div className="bg-sc" style={{ height: 6, borderRadius: 99 }}>
        <div style={{ width: pct + "%", height: "100%", background: "var(--primary)", borderRadius: 99 }} />
      </div>
    </div>
  );
}

function ZoneRow({ emoji, name, pct, value, status, tone = "warning" }) {
  return (
    <div className="bg-sc-low flex items-center gap-3" style={{ borderRadius: 18, padding: "12px 14px" }}>
      <div className="bg-sc-lowest flex items-center justify-center" style={{ width: 38, height: 38, borderRadius: 12, fontSize: 18, flexShrink: 0 }}>{emoji}</div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between">
          <span className="font-extrabold text-on-surface text-sm truncate">{name}</span>
          <span className="text-xs font-extrabold text-on-surface-variant">{value}</span>
        </div>
        <div className="bg-sc mt-2" style={{ height: 4, borderRadius: 99 }}>
          <div style={{ width: pct + "%", height: "100%", borderRadius: 99,
            background: tone === "tertiary" ? "var(--tertiary)" : tone === "emerald" ? "var(--primary-fixed-dim)" : tone === "slate" ? "var(--outline)" : "var(--warning)" }} />
        </div>
      </div>
      <Chip tone={tone === "tertiary" ? "tertiary" : tone === "emerald" ? "emerald" : tone === "slate" ? "slate" : "warning"}>{status}</Chip>
    </div>
  );
}

// ============== CONFIGURACIÓN ==============
function AdminConfig() {
  const [xp, setXp] = useState({
    create_sighting: 10,
    sighting_confirmed: 20,
    confirm_other: 3,
    comment: 1,
    complete_route: 10,
    create_event: 10,
    attend_event: 15,
    report_incident: 20,
  });

  const xpLabels = {
    create_sighting: "Crear avistamiento con evidencia",
    sighting_confirmed: "Avistamiento confirmado",
    confirm_other: "Confirmar avistamiento válido",
    comment: "Comentario (máx 10/día)",
    complete_route: "Completar ruta GPS",
    create_event: "Crear evento con asistentes",
    attend_event: "Asistir a evento confirmado",
    report_incident: "Reporte de incidente confirmado",
  };

  const [antiSpam, setAntiSpam] = useState({
    commentDailyCap: true,
    selfConfirmBlock: true,
    geoDedup: true,
    mediaDup: true,
    newUserWeight: true,
    falseReportPenalty: true,
  });

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Sistema · Reglas globales"
        title="Configuración"
        subtitle="Ajustes de XP, anti-spam, validación comunitaria y permisos"
        actions={
          <>
            <Btn variant="secondary" icon="restart_alt">Restablecer</Btn>
            <Btn variant="gradient" icon="save">Guardar cambios</Btn>
          </>
        }
      />

      <div className="grid grid-cols-3 gap-5">
        {/* XP rules */}
        <Card className="col-span-2">
          <div className="flex items-center justify-between mb-1">
            <h3 className="font-extrabold text-on-surface tracking-tight">Reglas de XP</h3>
            <Chip tone="emerald">8 acciones</Chip>
          </div>
          <p className="text-xs text-on-surface-variant mb-5">Puntos otorgados por acción. Cambios aplican a futuro; el ledger histórico no se altera.</p>

          <div className="space-y-3">
            {Object.entries(xp).map(([key, val]) => (
              <div key={key} className="bg-sc-low flex items-center gap-4" style={{ borderRadius: 20, padding: "14px 18px" }}>
                <div className="flex-1">
                  <div className="font-bold text-on-surface text-sm">{xpLabels[key]}</div>
                  <div className="text-[11px] font-mono text-on-surface-variant mt-0.5">{key}</div>
                </div>
                <button
                  className="bg-sc-lowest flex items-center justify-center"
                  style={{ width: 32, height: 32, borderRadius: 9999 }}
                  onClick={() => setXp({ ...xp, [key]: Math.max(0, val - 1) })}
                >
                  <Icon name="remove" className="text-[18px] text-on-surface-variant" />
                </button>
                <div className="bg-sc-lowest text-center font-black text-on-surface" style={{
                  width: 56, padding: "8px 0", borderRadius: 12,
                }}>+{val}</div>
                <button
                  className="bg-sc-lowest flex items-center justify-center"
                  style={{ width: 32, height: 32, borderRadius: 9999 }}
                  onClick={() => setXp({ ...xp, [key]: val + 1 })}
                >
                  <Icon name="add" className="text-[18px] text-primary" />
                </button>
              </div>
            ))}
          </div>
        </Card>

        {/* Confirmation rules */}
        <Card>
          <h3 className="font-extrabold text-on-surface tracking-tight mb-1">Validación Comunitaria</h3>
          <p className="text-xs text-on-surface-variant mb-5">Pesos por rol y umbrales de confirmación</p>

          <div className="text-[10px] font-extrabold uppercase tracking-[0.15em] text-on-surface-variant mb-3">Pesos por rol</div>
          <div className="space-y-2 mb-5">
            <WeightRow tone="slate" label="Visitante" weight={1} />
            <WeightRow tone="primary" label="Guía / Guardaparque" weight={2} />
            <WeightRow tone="tertiary" label="Investigador / Experto" weight={3} />
            <WeightRow tone="rose" label="Moderador / Admin" weight={4} />
          </div>

          <div className="bg-sc-low" style={{ borderRadius: 20, padding: 16 }}>
            <div className="text-[10px] font-extrabold uppercase tracking-[0.15em] text-on-surface-variant mb-2">Umbrales</div>
            <div className="space-y-2 text-sm">
              <div className="flex items-center justify-between">
                <span className="text-on-surface">Score normal mínimo</span>
                <span className="font-extrabold text-primary">≥ 6</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-on-surface">Confirmaciones distintas</span>
                <span className="font-extrabold text-primary">≥ 3</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-on-surface">Especie sensible · expertos</span>
                <span className="font-extrabold text-primary">≥ 1</span>
              </div>
            </div>
          </div>
        </Card>
      </div>

      {/* Anti-spam */}
      <Card>
        <div className="flex items-center justify-between mb-1">
          <h3 className="font-extrabold text-on-surface tracking-tight">Reglas Anti-Spam y Calidad</h3>
          <Chip tone="primary">Activas</Chip>
        </div>
        <p className="text-xs text-on-surface-variant mb-5">Controles automáticos sobre XP, reputación y duplicados</p>

        <div className="grid grid-cols-2 gap-3">
          <ToggleRow on={antiSpam.commentDailyCap} onChange={v => setAntiSpam({ ...antiSpam, commentDailyCap: v })}
            icon="schedule" title="Tope diario de XP por comentarios"
            sub="Máximo 10 comentarios con XP por día por usuario" />
          <ToggleRow on={antiSpam.selfConfirmBlock} onChange={v => setAntiSpam({ ...antiSpam, selfConfirmBlock: v })}
            icon="block" title="Bloquear auto-confirmación"
            sub="No otorgar XP por confirmar publicaciones propias" />
          <ToggleRow on={antiSpam.geoDedup} onChange={v => setAntiSpam({ ...antiSpam, geoDedup: v })}
            icon="location_off" title="Dedupe geográfico"
            sub="Avistamientos duplicados en mismo radio y ventana corta" />
          <ToggleRow on={antiSpam.mediaDup} onChange={v => setAntiSpam({ ...antiSpam, mediaDup: v })}
            icon="image_search" title="Detección de media duplicada"
            sub="Hash perceptual de fotos para revisión manual" />
          <ToggleRow on={antiSpam.newUserWeight} onChange={v => setAntiSpam({ ...antiSpam, newUserWeight: v })}
            icon="hourglass_top" title="Peso reducido usuarios nuevos"
            sub="Confirmaciones cuentan 0.5x durante los primeros 7 días" />
          <ToggleRow on={antiSpam.falseReportPenalty} onChange={v => setAntiSpam({ ...antiSpam, falseReportPenalty: v })}
            icon="trending_down" title="Penalizar reportes falsos"
            sub="Bajar trustScore tras 3 reportes rechazados consecutivos" />
        </div>
      </Card>

      <div className="grid grid-cols-2 gap-5">
        <Card>
          <h3 className="font-extrabold text-on-surface tracking-tight mb-4">Mapas Offline</h3>
          <div className="space-y-3">
            <KeyValRow icon="map" label="Proveedor" value="MapLibre" />
            <KeyValRow icon="package_2" label="Paquete actual" value="Galápagos v4.1 · 122 MB" />
            <KeyValRow icon="cloud_download" label="Nueva versión" value="v4.2 disponible (124 MB)" pill="emerald" pillLabel="Listo" />
            <KeyValRow icon="schedule" label="Última sincronización" value="20 Oct · 14:32" />
          </div>
          <div className="flex gap-2 mt-5">
            <Btn variant="secondary" icon="refresh" size="sm">Verificar</Btn>
            <Btn variant="gradient" icon="cloud_upload" size="sm">Publicar v4.2</Btn>
          </div>
        </Card>

        <Card>
          <h3 className="font-extrabold text-on-surface tracking-tight mb-4">Backup y Almacenamiento</h3>
          <div className="space-y-3">
            <KeyValRow icon="cloud" label="Firebase Storage usado" value="48.2 GB / 100 GB" />
            <KeyValRow icon="lock" label="Backup privado cifrado" value="Activo · Drive + iCloud" pill="emerald" pillLabel="OK" />
            <KeyValRow icon="movie" label="Límite de video" value="60 segundos" />
            <KeyValRow icon="auto_delete" label="Retención media social" value="Permanente (autor decide)" />
          </div>
          <div className="bg-sc-low mt-5" style={{ borderRadius: 16, padding: 12 }}>
            <div className="flex items-center justify-between text-xs">
              <span className="text-on-surface-variant">Uso del cupo</span>
              <span className="font-extrabold text-on-surface">48%</span>
            </div>
            <div className="bg-sc mt-2" style={{ height: 6, borderRadius: 99 }}>
              <div style={{ width: "48%", height: "100%", background: "var(--primary)", borderRadius: 99 }} />
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

function WeightRow({ tone, label, weight }) {
  return (
    <div className="flex items-center justify-between">
      <Chip tone={tone}>{label}</Chip>
      <span className="font-black text-on-surface tracking-tighter">{weight}×</span>
    </div>
  );
}

function ToggleRow({ on, onChange, icon, title, sub }) {
  return (
    <div className="bg-sc-low flex items-start gap-3" style={{ borderRadius: 20, padding: "16px 18px" }}>
      <div className="flex items-center justify-center flex-shrink-0" style={{ width: 36, height: 36, borderRadius: 12, background: "color-mix(in oklab, var(--primary) 12%, transparent)", color: "var(--primary)" }}>
        <Icon name={icon} className="text-[18px]" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-extrabold text-on-surface text-sm">{title}</div>
        <div className="text-[11px] text-on-surface-variant mt-1 leading-relaxed">{sub}</div>
      </div>
      <Switch on={on} onChange={onChange} />
    </div>
  );
}

function KeyValRow({ icon, label, value, pill, pillLabel }) {
  return (
    <div className="flex items-center gap-3">
      <Icon name={icon} className="text-[18px] text-on-surface-variant" />
      <div className="flex-1 min-w-0">
        <div className="text-[11px] text-on-surface-variant">{label}</div>
        <div className="text-sm font-bold text-on-surface truncate">{value}</div>
      </div>
      {pill && <Chip tone={pill}>{pillLabel}</Chip>}
    </div>
  );
}

Object.assign(window, { AdminEspecies, AdminEventos, AdminReportes, AdminConfig });
