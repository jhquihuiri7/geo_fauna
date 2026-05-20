/* Main screens: Muro, Agenda, Dashboard, Perfil */

// ---------- MURO ----------
function MuroScreen({ onNav }) {
  const [filter, setFilter] = useState("Recientes");
  return (
    <div className="bg-bg min-h-full" style={{ paddingBottom: 120 }}>
      <TopBar
        large
        title="EcoGuía"
        subtitle={<>
          <Icon name="local_fire_department" fill className="text-[12px]" style={{ color: "#f97316" }} />
          <span>12 Días · 2.4k XP</span>
        </>}
        leading={
          <Avatar name="Carlos J" tone="forest" size={42} emoji="🦫" status="on" />
        }
        trailing={
          <button className="bg-sc-lowest flex items-center justify-center" style={{ width: 40, height: 40, borderRadius: 9999 }}>
            <Icon name="notifications" className="text-primary" />
          </button>
        }
      />

      <main className="px-5 pt-6 space-y-9">
        {/* Eventos Próximos */}
        <section>
          <Kicker action={<button className="text-primary text-xs font-bold">Ver todos</button>}>
            Eventos Próximos
          </Kicker>
          <div className="flex gap-4 overflow-x-auto no-scrollbar pb-2 -mx-5 px-5">
            <EventCard date="24 OCT" xp="+25 XP" tone="tertiary" title="Workshop: Corales" body="Técnicas de monitoreo avanzado en Bahía Academia. ¿Te sumas?" />
            <EventCard date="28 OCT" xp="+40 XP" tone="primary" title="Limpieza de Playa" body="Juntos por Tortuga Bay. Remoción de microplásticos con el equipo." />
            <EventCard date="02 NOV" xp="+15 XP" tone="primary" title="Censo de Iguanas" body="Conteo en Plaza Sur. Reúne tu equipo a primera hora." />
          </div>
        </section>

        {/* Muro */}
        <section>
          <div className="flex items-center justify-between px-1 mb-5">
            <h3 className="text-[11px] font-extrabold uppercase tracking-[0.12em] text-on-surface-variant">Muro de Avistamientos</h3>
            <div className="flex gap-5">
              {["Recientes", "Populares"].map(f => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className="text-xs font-bold relative"
                  style={{
                    color: filter === f ? "var(--primary)" : "var(--outline)",
                  }}
                >
                  {f}
                  {filter === f && (
                    <span style={{
                      position: "absolute",
                      left: 0, right: 0, bottom: -6,
                      height: 2, borderRadius: 99, background: "var(--primary)",
                    }} />
                  )}
                </button>
              ))}
            </div>
          </div>

          <SightingCard
            author="Martín Solís"
            meta="Hace 2 horas · Isla Española"
            avatarTone="blue"
            avatarEmoji="🧑‍🔬"
            chip={{ tone: "emerald", label: "Estable" }}
            rank="RANGO: SENIOR"
            body="¡Miren este hallazgo! Un Albatros juvenil fuera de su zona típica. Su plumaje está impecable y parece estar en excelente estado de salud. ¿Alguien más lo ha visto hoy?"
            photoEmoji="🐦"
            photoLabel="ALBATROS — ESPAÑOLA"
            photoTone={2}
            comment={{
              author: "Dra. Elena Ruiz",
              avatarTone: "slate",
              avatarEmoji: "👩‍🔬",
              text: "¡Excelente registro! ¿Pudiste captar el sonido de sus llamados? Sería ideal para nuestra base de datos comparativa.",
            }}
          />

          <div style={{ height: 24 }} />

          <SightingCard
            author="Sofía Mendoza"
            meta="Hace 5 horas · Bahía Tortuga"
            avatarTone="coral"
            avatarEmoji="👩‍🌾"
            chip={{ tone: "warning", label: "Atención" }}
            rank="RANGO: AVANZADO"
            body="Grupo de iguanas marinas en zona inusual del intermareal. Conteo aproximado: 14 individuos adultos. Sin signos de estrés térmico."
            photoEmoji="🦎"
            photoLabel="IGUANA MARINA"
            photoTone={3}
          />
        </section>
      </main>
    </div>
  );
}

function EventCard({ date, xp, tone, title, body }) {
  return (
    <div
      className="bg-sc-lowest shadow-soft flex-shrink-0"
      style={{ width: 268, borderRadius: 32, padding: 22 }}
    >
      <Chip tone={tone}>{date} · {xp}</Chip>
      <h4 className="text-lg font-extrabold text-on-surface leading-tight mt-4 mb-2 tracking-tight">{title}</h4>
      <p className="text-on-surface-variant text-xs line-clamp-2 leading-relaxed mb-5">{body}</p>
      <button className="bg-primary w-full text-on-primary py-3 font-extrabold text-xs"
        style={{ borderRadius: 9999, boxShadow: "0 8px 20px color-mix(in oklab, var(--primary) 25%, transparent)" }}>
        Me anoto
      </button>
    </div>
  );
}

function SightingCard({ author, meta, avatarTone, avatarEmoji, chip, rank, body, photoEmoji, photoLabel, photoTone, comment }) {
  return (
    <article className="bg-sc-lowest overflow-hidden shadow-soft" style={{ borderRadius: 36 }}>
      <div className="p-5 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Avatar name={author} tone={avatarTone} emoji={avatarEmoji} size={42} status="default" />
          <div>
            <h4 className="text-[15px] font-extrabold text-on-surface leading-none">{author}</h4>
            <span className="text-[11px] text-on-surface-variant font-medium block mt-1">{meta}</span>
          </div>
        </div>
        <div className="flex flex-col items-end gap-1.5">
          <Chip tone={chip.tone}>{chip.label}</Chip>
          <span className="text-[9px] font-extrabold tracking-wider text-outline">{rank}</span>
        </div>
      </div>
      <div className="px-5 pb-4">
        <p className="text-on-surface text-[15px] leading-relaxed mb-4">{body}</p>
        <div style={{ borderRadius: 28, overflow: "hidden" }}>
          <Photo tone={photoTone} label={photoLabel} aspect="16/10" emoji={photoEmoji} />
        </div>
      </div>
      <div className="px-5 py-4 flex flex-wrap gap-2">
        <ActionBtn icon="verified" filled tone="primary">Confirmar (+2 XP)</ActionBtn>
        <ActionBtn icon="favorite" tone="slate">¡Qué foto!</ActionBtn>
        <ActionBtn icon="add_comment" tone="slate" className="ml-auto">¿Qué opinas?</ActionBtn>
      </div>
      {comment && (
        <div className="px-5 py-5 bg-sc-low">
          <div className="flex items-start gap-3">
            <Avatar name={comment.author} tone={comment.avatarTone} emoji={comment.avatarEmoji} size={32} />
            <div className="flex-1">
              <div className="bg-sc-lowest p-4 text-xs shadow-card" style={{ borderRadius: 24 }}>
                <span className="font-extrabold text-on-surface block mb-1">{comment.author}</span>
                <p className="text-on-surface-variant leading-relaxed">{comment.text}</p>
              </div>
              <button className="text-[10px] font-extrabold text-primary mt-2 ml-2">Responder</button>
            </div>
          </div>
        </div>
      )}
    </article>
  );
}

function ActionBtn({ icon, children, tone, className = "", filled }) {
  const styles = {
    primary: { bg: "color-mix(in oklab, var(--primary) 10%, transparent)", fg: "var(--primary)" },
    slate: { bg: "var(--surface-container-low)", fg: "var(--on-surface-variant)" },
  };
  const s = styles[tone] || styles.slate;
  return (
    <button
      className={"flex items-center gap-2 px-4 py-2.5 text-xs font-black " + className}
      style={{ background: s.bg, color: s.fg, borderRadius: 9999 }}
    >
      <Icon name={icon} fill={filled} className="text-[16px]" />
      {children}
    </button>
  );
}

// ---------- AGENDA ----------
function AgendaScreen({ onNav }) {
  return (
    <div className="bg-surface min-h-full" style={{ paddingBottom: 120 }}>
      <TopBar
        large
        title="Mi Bitácora"
        leading={<Avatar size={40} tone="forest" emoji="🚙" />}
        trailing={
          <span className="flex items-center gap-1.5">
            <Icon name="cloud_done" fill className="text-primary" />
          </span>
        }
      />

      <main className="px-6 pt-6 space-y-6">
        <section>
          <h1 className="text-[40px] font-black tracking-tighter text-on-surface leading-none">Tu Agenda</h1>
          <p className="text-on-surface-variant mt-2 text-[15px]">Logística de campo para hoy, 24 de Octubre</p>
        </section>

        {/* Weather */}
        <section className="bg-sc-lowest shadow-card flex items-center justify-between" style={{ borderRadius: 32, padding: "20px 22px" }}>
          <div>
            <div className="flex items-center gap-1.5 mb-1.5">
              <Icon name="location_on" fill className="text-primary text-[18px]" />
              <span className="text-sm font-extrabold text-on-surface">Puerto Ayora, SC</span>
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-4xl font-black text-on-surface tracking-tighter">28°C</span>
              <span className="text-sm text-on-surface-variant">Despejado</span>
            </div>
            <div className="flex gap-4 mt-3">
              <div className="flex items-center gap-1">
                <Icon name="humidity_low" className="text-[14px] text-primary" />
                <span className="text-[10px] font-extrabold uppercase tracking-wider text-on-surface-variant">65% Hum.</span>
              </div>
              <div className="flex items-center gap-1">
                <Icon name="sunny" className="text-[14px] text-primary" />
                <span className="text-[10px] font-extrabold uppercase tracking-wider text-on-surface-variant">UV 8 (Alto)</span>
              </div>
            </div>
          </div>
          <div className="flex items-center justify-center" style={{
            width: 72, height: 72, borderRadius: 9999,
            background: "color-mix(in oklab, var(--primary) 10%, transparent)",
          }}>
            <Icon name="wb_sunny" fill className="text-[36px] text-primary" />
          </div>
        </section>

        {/* Calendar */}
        <section className="flex gap-3 overflow-x-auto no-scrollbar -mx-6 px-6 pb-2">
          {[
            { d: "Hoy", n: 24, active: true },
            { d: "Vie", n: 25 },
            { d: "Sáb", n: 26 },
            { d: "Dom", n: 27 },
            { d: "Lun", n: 28 },
          ].map(it => (
            <div
              key={it.n}
              className={it.active ? "bg-primary-container" : "bg-sc-low"}
              style={{
                width: 72, height: 92, borderRadius: 26,
                display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
                flexShrink: 0,
                color: it.active ? "var(--on-primary-container)" : "var(--on-surface)",
              }}
            >
              <span className="text-[10px] uppercase tracking-widest font-bold opacity-80">{it.d}</span>
              <span className="text-2xl font-black mt-1">{it.n}</span>
            </div>
          ))}
        </section>

        {/* Timeline */}
        <section className="relative" style={{ paddingLeft: 32 }}>
          <div style={{
            position: "absolute", left: 11, top: 18, bottom: 18,
            width: 2, background: "var(--outline-variant)", opacity: 0.4,
          }} />

          {/* Active */}
          <div className="relative" style={{ marginBottom: 18 }}>
            <div style={{
              position: "absolute", left: -27, top: 36,
              width: 24, height: 24, borderRadius: 9999,
              background: "var(--primary)",
              border: "5px solid var(--surface)",
              boxShadow: "0 0 0 4px color-mix(in oklab, var(--primary) 25%, transparent)",
            }} />
            <div className="bg-sc-lowest shadow-card" style={{ borderRadius: 32, padding: 22 }}>
              <div className="flex justify-between items-start mb-4">
                <div>
                  <span className="text-[10px] font-extrabold uppercase tracking-widest text-primary block mb-1">
                    Activo · 08:00 - 12:00
                  </span>
                  <h3 className="text-xl font-extrabold text-on-surface tracking-tight">Seymour Norte</h3>
                </div>
                <div className="bg-secondary-container flex items-center justify-center" style={{ width: 48, height: 48, borderRadius: 9999, fontSize: 24 }}>
                  🦭
                </div>
              </div>
              <div className="space-y-2.5">
                <div className="flex items-center gap-3 text-on-surface-variant">
                  <Icon name="directions_boat" className="text-[18px]" />
                  <span className="text-sm font-medium">Yate "Sea Lion III"</span>
                </div>
                <div className="flex items-center gap-3 text-on-surface-variant">
                  <Icon name="location_on" className="text-[18px]" />
                  <span className="text-sm font-medium">Punto de desembarque seco</span>
                </div>
              </div>
              <button className="bg-primary text-on-primary mt-5 w-full flex items-center justify-center gap-2 font-extrabold text-sm"
                style={{ padding: "14px 20px", borderRadius: 9999, boxShadow: "0 8px 20px color-mix(in oklab, var(--primary) 25%, transparent)" }}>
                <Icon name="play_circle" fill className="text-[18px]" /> Iniciar Ruta
              </button>
            </div>
          </div>

          {/* Inactive */}
          <div className="relative" style={{ opacity: 0.6 }}>
            <div style={{
              position: "absolute", left: -22, top: 30,
              width: 14, height: 14, borderRadius: 9999,
              background: "var(--outline-variant)",
              border: "3px solid var(--surface)",
            }} />
            <div className="dashed bg-sc-low" style={{ borderRadius: 32, padding: 22 }}>
              <div className="flex justify-between items-start mb-3">
                <div>
                  <span className="text-[10px] font-extrabold uppercase tracking-widest text-on-surface-variant block mb-1">
                    Próximo · 14:00 - 17:00
                  </span>
                  <h3 className="text-xl font-extrabold text-on-surface tracking-tight">Estación Darwin</h3>
                </div>
                <div className="flex items-center justify-center" style={{ width: 40, height: 40, borderRadius: 9999, background: "var(--surface-container-high)", fontSize: 20 }}>
                  🐢
                </div>
              </div>
              <div className="flex items-center gap-3 text-on-surface-variant">
                <Icon name="groups" className="text-[18px]" />
                <span className="text-sm font-medium">Charla logística: Conservación Terrestre</span>
              </div>
            </div>
          </div>
        </section>
      </main>
    </div>
  );
}

Object.assign(window, { MuroScreen, AgendaScreen });
