import { useEffect, useState } from "react";

const API = import.meta.env.VITE_API_URL;

export default function App() {
  const [q, setQ] = useState(null);
  const [err, setErr] = useState("");

  async function loadRandom() {
    try {
      setErr("");
      const r = await fetch(`${API}/questions/random`);
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      setQ(await r.json());
    } catch (e) {
      setErr(e.message);
    }
  }

  useEffect(() => { loadRandom(); }, []);

  return (
    <div style={{ maxWidth: 640, margin: "3rem auto", fontFamily: "Inter, system-ui, sans-serif" }}>
      <h1 style={{ marginBottom: 8 }}>Trivia</h1>
      <p style={{ color: "#666", marginTop: 0 }}>FastAPI + Postgres demo</p>

      {err && <div style={{ color: "crimson" }}>Error: {err}</div>}

      {!q ? (
        <p>Loading…</p>
      ) : (
        <div style={{ border: "1px solid #eee", borderRadius: 12, padding: 16 }}>
          <div style={{ marginBottom: 12 }}>{q.question}</div>
          <ol type="A" style={{ lineHeight: 1.9 }}>
            <li>{q.option_a}</li>
            <li>{q.option_b}</li>
            <li>{q.option_c}</li>
            <li>{q.option_d}</li>
          </ol>
          <button onClick={loadRandom} style={{ marginTop: 12, padding: "8px 12px", borderRadius: 8 }}>
            New random
          </button>
        </div>
      )}
    </div>
  );
}
