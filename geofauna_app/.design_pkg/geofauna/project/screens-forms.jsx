/* Forms: RegistroCampo (Nuevo), RegistroTour, CrearEvento */

function NuevoHubScreen({ onNav, subScreen = "campo" }) {
  // 3-way tab: Monitoreo (campo), Agenda (tour), Evento
  const tabs = ["Monitoreo", "Agenda", "Evento"];
  const tabToScreen = { "Monitoreo": "campo", "Agenda": "tour", "Evento": "evento" };
  const screenToTab = { "campo": "Monitoreo", "tour": "Agenda", "evento": "Evento" };
  const active = screenToTab[subScreen];

  return (
    <div className="bg-surface min-h-full" style={{ paddingBottom: 120 }}>
      <TopBar
        title="EcoGuía Galápagos"
        leading={subScreen === "tour" ? (
          <button onClick={() => onNav("dashboard")} className="text-primary"><Icon name="arrow_back" /></button>
        ) : (
          <Avatar size={40} tone="forest" emoji="🦫" status="on" />
        )}
        trailing={subScreen === "evento" ? (
          <>
            <button className="bg-sc-low flex items-center justify-center" style={{ width: 36, height: 36, borderRadius: 9999 }}>
              <Icon name="settings" className="text-on-surface text-[18px]" />
            </button>
            <Avatar size={36} tone="forest" emoji="🦫" />
          </>
        ) : (
          <Avatar size={36} tone="primary" emoji="🐢" />
        )}
      />

      <div className="px-5 pt-4">
        <SegTabs tabs={tabs} active={active} onChange={t => onNav("nuevo:" + tabToScreen[t])} />
      </div>

      {subScreen === "campo" && <FieldRecord onNav={onNav} />}
      {subScreen === "tour" && <TourRecord onNav={onNav} />}
      {subScreen === "evento" && <EventCreate onNav={onNav} />}
    </div>
  );
}

function FieldRecord({ onNav }) {
  const [cat, setCat] = useState("Fauna");
  const cats = [
    { name: "Fauna", emoji: "🐢", tone: "primary" },
    { name: "Incidente", emoji: "⚠️", tone: "warning" },
    { name: "Flora", emoji: "🌿", tone: "emerald" },
    { name: "Basura", emoji: "🗑️", tone: "slate" },
  ];

  return (
    <main className="px-6 pt-6 space-y-6">
      <section>
        <div className="flex items-start justify-between gap-4">
          <div>
            <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-primary mb-1">Módulo de Campo</div>
            <h1 className="text-[34px] font-black tracking-tighter text-on-surface leading-none">
              Nuevo Registro<br />de Campo
            </h1>
            <p className="text-on-surface-variant text-sm mt-3 leading-relaxed max-w-xs">
              Documenta tus hallazgos científicos o reporta incidentes en tiempo real.
            </p>
          </div>
          <div className="bg-secondary-container flex items-center justify-center" style={{ width: 52, height: 52, borderRadius: 9999, flexShrink: 0 }}>
            <Icon name="calendar_month" className="text-on-secondary-container" />
          </div>
        </div>
      </section>

      <section>
        <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant mb-2">Ubicación del Registro</div>
        <div className="topo-map relative overflow-hidden" style={{ borderRadius: 28, minHeight: 168 }}>
          <button className="absolute top-3 right-3 bg-white/90 flex items-center justify-center"
            style={{ width: 36, height: 36, borderRadius: 9999, boxShadow: "0 4px 12px rgba(0,0,0,.2)" }}>
            <Icon name="explore" className="text-primary text-[20px]" />
          </button>
          <div style={{
            position: "absolute", top: "45%", left: "44%",
            width: 32, height: 32, borderRadius: 9999, background: "var(--primary)",
            display: "flex", alignItems: "center", justifyContent: "center",
            border: "4px solid #fff", boxShadow: "0 6px 18px rgba(0,0,0,.4)",
          }}>
            <Icon name="location_on" fill className="text-white text-[16px]" />
          </div>
          <div className="absolute bottom-3 left-3 glass" style={{ padding: "8px 14px", borderRadius: 18 }}>
            <div className="text-[9px] font-extrabold uppercase tracking-widest text-on-surface-variant">Ubicación Actual</div>
            <div className="text-sm font-extrabold text-on-surface">Canal de Itabaca</div>
          </div>
        </div>
      </section>

      <section>
        <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant mb-3">Seleccionar Categoría</div>
        <div className="grid grid-cols-2 gap-3">
          {cats.map(c => {
            const isActive = c.name === cat;
            return (
              <button key={c.name} onClick={() => setCat(c.name)}
                className={(isActive ? "bg-primary text-on-primary " : "bg-sc-low text-on-surface ") + "flex items-center gap-2 px-4 font-extrabold text-sm"}
                style={{
                  borderRadius: 9999, height: 52,
                  boxShadow: isActive ? "0 8px 20px color-mix(in oklab, var(--primary) 25%, transparent)" : "none",
                }}>
                <span style={{ fontSize: 18 }}>{c.emoji}</span>
                {c.name}
              </button>
            );
          })}
        </div>
      </section>

      <section className="dashed bg-sc-low flex items-center gap-3" style={{ borderRadius: 28, padding: 20 }}>
        <div className="bg-secondary-container flex items-center justify-center" style={{ width: 52, height: 52, borderRadius: 9999, flexShrink: 0 }}>
          <Icon name="add_a_photo" className="text-on-secondary-container" />
        </div>
        <div>
          <div className="font-extrabold text-on-surface text-sm">Capturar Evidencia</div>
          <div className="text-xs text-on-surface-variant mt-0.5">Toma una foto del hallazgo</div>
        </div>
      </section>

      <section className="space-y-4">
        <FieldGroup cap="Fecha y Hora">
          <div className="flex items-center gap-3">
            <Icon name="event" className="text-primary" />
            <div>
              <div className="text-sm font-bold text-on-surface">24/05/2024 — 09:45 AM</div>
              <div className="text-[10px] font-extrabold uppercase tracking-widest text-on-surface-variant mt-0.5">Toca para cambiar</div>
            </div>
          </div>
        </FieldGroup>
        <FieldGroup cap="Especie (Opcional)">
          <div className="flex items-center gap-3">
            <Icon name="science" className="text-outline" />
            <input className="bg-transparent outline-none flex-1 text-sm text-on-surface placeholder:text-outline" placeholder="Ej: Chelonoidis nigra…" />
          </div>
        </FieldGroup>
        <FieldGroup cap="Cantidad de Individuos">
          <div className="flex items-center gap-3">
            <Icon name="groups" className="text-outline" />
            <input className="bg-transparent outline-none flex-1 text-sm text-on-surface" defaultValue="1" />
          </div>
        </FieldGroup>
        <div>
          <Cap className="mb-2">Notas y Observaciones</Cap>
          <textarea
            className="bg-sc-low text-on-surface text-sm placeholder:text-outline w-full outline-none"
            placeholder="Describe el estado del espécimen o los detalles del incidente observado…"
            style={{ borderRadius: 24, padding: 16, minHeight: 88, resize: "vertical" }}
          />
        </div>

        <div className="bg-sc-low flex items-center justify-between" style={{ borderRadius: 24, padding: "14px 18px" }}>
          <div>
            <div className="font-extrabold text-on-surface text-sm">Publicar en Muro</div>
            <div className="text-[11px] text-on-surface-variant mt-0.5 max-w-[220px]">Compartir este registro con la comunidad de guías</div>
          </div>
          <Switch on={true} onChange={() => {}} />
        </div>

        <button className="organic-gradient w-full flex items-center justify-center gap-2 font-extrabold"
          style={{ color: "#fff", height: 56, borderRadius: 9999, boxShadow: "0 8px 25px rgba(0,105,72,0.3)", marginTop: 8 }}>
          <Icon name="upload" /> Subir Reporte
        </button>
      </section>
    </main>
  );
}

function FieldGroup({ cap, children }) {
  return (
    <div>
      <Cap className="mb-2">{cap}</Cap>
      <div className="bg-sc-low" style={{ borderRadius: 9999, padding: "12px 18px" }}>
        {children}
      </div>
    </div>
  );
}

function TourRecord({ onNav }) {
  const [type, setType] = useState("Terrestre");
  const types = [
    { name: "Marino", icon: "sailing", tone: "tertiary" },
    { name: "Terrestre", icon: "landscape", tone: "primary" },
    { name: "Avistamiento", icon: "visibility", tone: "coral" },
    { name: "Educativo", icon: "school", tone: "slate" },
    { name: "Tour diario", icon: "calendar_month", tone: "tertiary" },
    { name: "Crucero", icon: "directions_boat", tone: "primary" },
  ];

  return (
    <main className="px-6 pt-6 space-y-6">
      <section>
        <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-primary mb-1">Registro de Expedición</div>
        <h1 className="text-[40px] font-black tracking-tighter text-on-surface leading-none">Nuevo Registro</h1>
      </section>

      <section>
        <h3 className="font-extrabold text-on-surface text-base pl-3" style={{ borderLeft: "3px solid var(--primary)" }}>Información Básica</h3>
        <div className="space-y-3 mt-4">
          <FieldGroup cap="Nombre del Tour">
            <div className="flex items-center gap-3">
              <input className="bg-transparent outline-none flex-1 text-sm text-on-surface placeholder:text-outline" placeholder="e.g. Tour León Dormido AM" />
              <Icon name="edit_note" className="text-outline text-[20px]" />
            </div>
          </FieldGroup>
          <FieldGroup cap="Fecha">
            <div className="flex items-center justify-between">
              <span className="text-sm text-outline">mm/dd/yyyy</span>
              <Icon name="calendar_today" className="text-outline" />
            </div>
          </FieldGroup>
          <div className="grid grid-cols-2 gap-3">
            <FieldGroup cap="Hora Inicio">
              <div className="flex items-center justify-between">
                <span className="text-sm text-outline">--:-- --</span>
                <Icon name="schedule" className="text-outline" />
              </div>
            </FieldGroup>
            <FieldGroup cap="Hora Fin">
              <div className="flex items-center justify-between">
                <span className="text-sm text-outline">--:-- --</span>
                <Icon name="hourglass_empty" className="text-outline" />
              </div>
            </FieldGroup>
          </div>
        </div>
      </section>

      <section>
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-extrabold text-on-surface text-base pl-3" style={{ borderLeft: "3px solid var(--primary)" }}>Tipo de Tour</h3>
          <Chip tone="emerald">Selección Única</Chip>
        </div>
        <div className="grid grid-cols-3 gap-3">
          {types.map(t => {
            const isActive = t.name === type;
            return (
              <button key={t.name} onClick={() => setType(t.name)}
                className="bg-sc-lowest flex flex-col items-center justify-center"
                style={{
                  borderRadius: 24, padding: "16px 8px",
                  boxShadow: isActive ? "0 0 0 2px var(--primary), 0 6px 16px rgba(0,105,72,.15)" : "var(--shadow-card)",
                }}>
                <div
                  className="flex items-center justify-center mb-2"
                  style={{
                    width: 44, height: 44, borderRadius: 9999,
                    background: isActive
                      ? "color-mix(in oklab, var(--primary) 18%, transparent)"
                      : t.tone === "tertiary" ? "color-mix(in oklab, var(--tertiary) 12%, transparent)"
                      : t.tone === "coral" ? "color-mix(in oklab, #ef6e4d 14%, transparent)"
                      : t.tone === "slate" ? "color-mix(in oklab, var(--secondary) 14%, transparent)"
                      : "color-mix(in oklab, var(--primary) 12%, transparent)"
                  }}
                >
                  <Icon name={t.icon}
                    className={
                      t.tone === "tertiary" ? "text-tertiary" :
                      t.tone === "coral" ? "" :
                      t.tone === "slate" ? "text-secondary" :
                      "text-primary"
                    }
                    style={t.tone === "coral" ? { color: "#ef6e4d" } : {}}
                  />
                </div>
                <span className="text-[12px] font-extrabold text-on-surface">{t.name}</span>
              </button>
            );
          })}
        </div>
      </section>

      <section className="organic-gradient flex items-center gap-4" style={{ borderRadius: 28, padding: "16px 20px", color: "#fff" }}>
        <Icon name="eco" fill className="text-[24px]" />
        <div>
          <div className="font-extrabold">Impacto Ambiental</div>
          <div className="text-xs opacity-90 mt-0.5 leading-relaxed">
            Recuerda registrar cualquier avistamiento de especies invasoras.
          </div>
        </div>
      </section>

      <section>
        <button className="organic-gradient w-full flex items-center justify-center gap-2 font-extrabold text-[15px]"
          style={{ color: "#fff", height: 56, borderRadius: 9999, boxShadow: "0 8px 25px rgba(0,105,72,0.3)" }}>
          <Icon name="rocket_launch" /> Confirmar Tour
        </button>
      </section>
    </main>
  );
}

function EventCreate({ onNav }) {
  const [type, setType] = useState("Misión");
  return (
    <main className="px-6 pt-6 space-y-6">
      <section>
        <h1 className="text-[40px] font-black tracking-tighter text-on-surface leading-none">Crear Evento</h1>
        <p className="text-on-surface-variant text-sm mt-2">Registre una nueva actividad para el equipo de campo.</p>
      </section>

      <section className="bg-sc-lowest shadow-card space-y-4" style={{ borderRadius: 32, padding: 22 }}>
        <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant">Información Básica</div>
        <div className="bg-sc-low" style={{ borderRadius: 9999, padding: "14px 22px" }}>
          <input className="bg-transparent outline-none w-full text-sm text-on-surface placeholder:text-outline" placeholder="Título del evento" />
        </div>
        <div className="bg-sc-low flex items-center justify-between" style={{ borderRadius: 9999, padding: "12px 18px" }}>
          <span className="flex items-center gap-2 text-on-surface text-sm font-bold">
            <Icon name="visibility" className="text-primary" />
            Visibilidad Pública
          </span>
          <Switch on={true} onChange={() => {}} />
        </div>

        <div className="grid grid-cols-3 gap-3">
          {[
            { name: "Misión", icon: "science" },
            { name: "Taller", icon: "groups" },
            { name: "Limpieza", icon: "delete" },
          ].map(t => {
            const isActive = t.name === type;
            return (
              <button key={t.name} onClick={() => setType(t.name)}
                className="flex flex-col items-center justify-center gap-2"
                style={{
                  padding: "14px 6px", borderRadius: 24,
                  background: isActive ? "color-mix(in oklab, var(--primary) 10%, transparent)" : "var(--surface-container-low)",
                  border: isActive ? "2px solid var(--primary)" : "2px solid transparent",
                }}>
                <Icon name={t.icon} className={isActive ? "text-primary" : "text-on-surface-variant"} />
                <span className={"text-[10px] font-extrabold uppercase tracking-widest " + (isActive ? "text-primary" : "text-on-surface-variant")}>
                  {t.name}
                </span>
              </button>
            );
          })}
        </div>
      </section>

      <section className="bg-sc-lowest shadow-card" style={{ borderRadius: 32, padding: 22 }}>
        <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant mb-3">Objetivos Técnicos</div>
        <textarea
          className="bg-sc-low text-on-surface text-sm w-full outline-none placeholder:text-outline"
          placeholder="Describa el propósito y metas de la actividad…"
          style={{ borderRadius: 24, padding: 16, minHeight: 110, resize: "vertical" }}
        />
      </section>

      <section className="bg-sc-lowest shadow-card" style={{ borderRadius: 32, padding: 22 }}>
        <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant mb-3">Ubicación del Encuentro</div>
        <div className="bg-sc-low flex items-center gap-3" style={{ borderRadius: 9999, padding: "14px 18px" }}>
          <Icon name="location_on" className="text-outline" />
          <span className="text-sm text-on-surface flex-1">Estación Científica Charles Darwin</span>
        </div>
      </section>

      <section className="bg-sc-lowest shadow-card" style={{ borderRadius: 32, padding: 22 }}>
        <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant mb-3">Fecha</div>
        <div className="bg-sc-low flex items-center justify-between" style={{ borderRadius: 9999, padding: "14px 18px" }}>
          <span className="flex items-center gap-3">
            <Icon name="event" className="text-primary" />
            <span className="text-sm text-outline">mm/dd/yyyy</span>
          </span>
          <Icon name="calendar_month" className="text-outline" />
        </div>
      </section>

      <section className="bg-sc-lowest shadow-card" style={{ borderRadius: 32, padding: 22 }}>
        <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant mb-3">Horario</div>
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-sc-low flex items-center justify-between" style={{ borderRadius: 9999, padding: "14px 18px" }}>
            <span className="text-sm text-outline">--:-- --</span>
            <Icon name="schedule" className="text-outline text-[18px]" />
          </div>
          <div className="bg-sc-low flex items-center justify-between" style={{ borderRadius: 9999, padding: "14px 18px" }}>
            <span className="text-sm text-outline">--:-- --</span>
            <Icon name="schedule" className="text-outline text-[18px]" />
          </div>
        </div>
      </section>

      <section className="bg-sc-lowest shadow-card" style={{ borderRadius: 32, padding: 22 }}>
        <div className="text-[10px] font-extrabold uppercase tracking-[0.18em] text-on-surface-variant mb-3">Participantes / Guías Invitados</div>
        <div className="flex items-center gap-3">
          <button className="bg-sc-low flex items-center justify-center" style={{ width: 44, height: 44, borderRadius: 9999 }}>
            <Icon name="person_add" className="text-on-surface" />
          </button>
          <div className="flex-1 bg-sc-low text-center font-black text-on-surface text-lg" style={{ borderRadius: 9999, padding: "10px 0" }}>10</div>
          <button className="flex items-center justify-center"
            style={{ width: 44, height: 44, borderRadius: 9999, background: "color-mix(in oklab, var(--primary) 14%, transparent)" }}>
            <Icon name="list" className="text-primary" />
          </button>
        </div>
      </section>

      <button className="organic-gradient w-full flex items-center justify-center gap-2 font-extrabold text-[15px]"
        style={{ color: "#fff", height: 60, borderRadius: 9999, boxShadow: "0 8px 25px rgba(0,105,72,0.3)" }}>
        Confirmar Evento <Icon name="rocket_launch" />
      </button>
    </main>
  );
}

Object.assign(window, { NuevoHubScreen });
