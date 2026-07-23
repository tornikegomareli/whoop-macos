const github = "https://github.com/tornikegomareli/whoop-macos";
const version = "0.1.0-alpha.1";
const releaseTag = `v${version}`;
const releasePage = `${github}/releases/tag/${releaseTag}`;
const download = `${github}/releases/download/${releaseTag}/WhoopScope-${version}-macOS.zip`;
const checksums = `${github}/releases/download/${releaseTag}/SHA256SUMS.txt`;

const features = [
  {
    eyebrow: "Today",
    title: "A calm daily picture",
    copy: "Recovery, strain, sleep, and recent workouts in a dashboard designed for quick understanding.",
    accent: "green",
    icon: "◉",
  },
  {
    eyebrow: "Explore",
    title: "History without limits",
    copy: "Compare 7, 30, and 90-day trends, inspect complete records, and search every synced workout.",
    accent: "blue",
    icon: "↗",
  },
  {
    eyebrow: "Everywhere",
    title: "Native Mac surfaces",
    copy: "Keep the essentials in your menu bar and desktop widgets, with useful actions in Siri and Spotlight.",
    accent: "purple",
    icon: "⌘",
  },
  {
    eyebrow: "Ask",
    title: "Grounded in your data",
    copy: "Ask natural-language questions using Apple’s on-device model or an OpenAI key you bring yourself.",
    accent: "orange",
    icon: "✦",
  },
];

const privacyPoints = [
  "WHOOP records stay in WhoopScope’s sandboxed local database.",
  "Tokens and model API keys live in Apple Keychain.",
  "Apple Intelligence questions and answers remain on-device.",
  "Cloud evidence leaves the Mac only after you select OpenAI.",
  "No ads, analytics, behavioral tracking, or paid tier.",
];

export default function Home() {
  return (
    <main>
      <nav className="nav shell" aria-label="Primary navigation">
        <a className="brand" href="#top" aria-label="WhoopScope home">
          <img src="/icon.png" width="34" height="34" alt="" />
          <span>WhoopScope</span>
        </a>
        <div className="navLinks">
          <a href="#features">Features</a>
          <a href="#privacy">Privacy</a>
          <a href="#open-source">Open source</a>
          <a className="navDownload" href={download}>
            Download
          </a>
        </div>
      </nav>

      <section className="hero shell" id="top">
        <div className="heroGlow" aria-hidden="true" />
        <div className="pill">
          <span className="statusDot" />
          Free and open source · Public alpha
        </div>
        <h1>
          Your WHOOP history,
          <br />
          {" "}
          <span>at home on Mac.</span>
        </h1>
        <p className="heroCopy">
          A fast, private, native dashboard for understanding your recovery,
          sleep, strain, and workouts—without surrendering your health history.
        </p>
        <div className="heroActions">
          <a className="button primary" href={download}>
            <AppleMark />
            Download for macOS
          </a>
          <a className="button secondary" href={github}>
            <GitHubMark />
            View source
          </a>
        </div>
        <p className="requirements">
          macOS 26+ · Apple silicon · version {version} ·{" "}
          <a href={checksums}>SHA-256</a>
        </p>

        <div className="heroFrame">
          <div className="frameTop">
            <span className="traffic red" />
            <span className="traffic yellow" />
            <span className="traffic green" />
            <span className="sampleLabel">Synthetic sample data</span>
          </div>
          <img
            src="/dashboard.png"
            alt="WhoopScope Today dashboard showing synthetic recovery, strain, sleep, and workout trends"
          />
        </div>
      </section>

      <section className="trustStrip" aria-label="Product principles">
        <div className="shell trustItems">
          <span>Official WHOOP API</span>
          <i />
          <span>Local-first storage</span>
          <i />
          <span>Native SwiftUI</span>
          <i />
          <span>Apache 2.0</span>
        </div>
      </section>

      <section className="section shell" id="features">
        <div className="sectionHeading">
          <p className="kicker">Built for the glance and the deep dive</p>
          <h2>Everything important. Nothing noisy.</h2>
          <p>
            WhoopScope covers the data available through WHOOP’s public API and
            presents it at the right level for the moment.
          </p>
        </div>
        <div className="featureGrid">
          {features.map((feature) => (
            <article
              className={`featureCard ${feature.accent}`}
              key={feature.title}
            >
              <div className="featureIcon" aria-hidden="true">
                {feature.icon}
              </div>
              <p className="cardEyebrow">{feature.eyebrow}</p>
              <h3>{feature.title}</h3>
              <p>{feature.copy}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="section shell showcase">
        <div className="showcaseCopy">
          <p className="kicker">Thirty seconds becomes three</p>
          <h2>See the shape of your month.</h2>
          <p>
            Readiness, HRV, resting heart rate, and strain line up on one
            timeline, with clear period-over-period comparisons.
          </p>
          <ul>
            <li>7, 30, and 90-day ranges</li>
            <li>Interactive native charts</li>
            <li>Complete locally stored history</li>
          </ul>
        </div>
        <div className="mediaFrame">
          <img
            src="/trends.png"
            alt="WhoopScope trends screen using synthetic data"
          />
        </div>
      </section>

      <section className="section shell demoSection">
        <div className="sectionHeading compact">
          <p className="kicker">A quick tour</p>
          <h2>Thirteen seconds of WhoopScope.</h2>
          <p>Every value and identity in this recording is synthetic.</p>
        </div>
        <video
          className="demoVideo"
          controls
          muted
          loop
          playsInline
          preload="metadata"
          poster="/dashboard.png"
        >
          <source src="/whoopscope-demo.mp4" type="video/mp4" />
          Your browser does not support embedded video.
        </video>
      </section>

      <section className="privacyBand" id="privacy">
        <div className="shell privacyGrid">
          <div>
            <p className="kicker">Privacy is architecture</p>
            <h2>Your health history is not a business model.</h2>
            <p className="privacyIntro">
              WhoopScope is free. It has no account system of its own, no
              analytics SDK, and no server that receives your WHOOP records.
            </p>
            <a className="textLink" href={`${github}/blob/main/PRIVACY.md`}>
              Read the privacy policy <span>↗</span>
            </a>
          </div>
          <ul className="privacyList">
            {privacyPoints.map((point) => (
              <li key={point}>
                <span aria-hidden="true">✓</span>
                {point}
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="section shell openSource" id="open-source">
        <div className="sourceMark" aria-hidden="true">
          {"</>"}
        </div>
        <p className="kicker">Open by default</p>
        <h2>Inspect it. Build it. Improve it.</h2>
        <p>
          The Mac app, iPhone companion, authentication broker, demo fixtures,
          and this site are available under the Apache 2.0 license. The project
          is developed in public and will remain free.
        </p>
        <div className="heroActions">
          <a className="button primary" href={github}>
            <GitHubMark />
            Explore the repository
          </a>
          <a
            className="button secondary"
            href={`${github}/blob/main/CONTRIBUTING.md`}
          >
            Contribute
          </a>
        </div>
      </section>

      <section className="section shell faq">
        <div className="sectionHeading compact">
          <p className="kicker">Before you download</p>
          <h2>Good to know.</h2>
        </div>
        <div className="faqGrid">
          <article>
            <h3>Is WhoopScope affiliated with WHOOP?</h3>
            <p>
              No. It is an independent project built exclusively on WHOOP’s
              official public Developer API.
            </p>
          </article>
          <article>
            <h3>Why is sign-in capacity limited?</h3>
            <p>
              WHOOP limits unapproved Developer applications to a small member
              allowance. Broader access depends on WHOOP approval.
            </p>
          </article>
          <article>
            <h3>Does it cost anything?</h3>
            <p>
              WhoopScope is free. If you select OpenAI, that provider may bill
              usage to the API key you supply. On-device chat has no API bill.
            </p>
          </article>
          <article>
            <h3>Is this a medical app?</h3>
            <p>
              No. WhoopScope is an educational fitness-history tool and does
              not diagnose conditions or provide medical advice.
            </p>
          </article>
        </div>
      </section>

      <section className="cta">
        <div className="shell ctaInner">
          <img src="/icon.png" width="88" height="88" alt="" />
          <div>
            <p className="kicker">Start with the sample data</p>
            <h2>Bring your WHOOP history home.</h2>
          </div>
          <a className="button primary" href={download}>
            Download alpha
          </a>
        </div>
      </section>

      <footer className="footer shell">
        <a className="brand" href="#top">
          <img src="/icon.png" width="28" height="28" alt="" />
          <span>WhoopScope</span>
        </a>
        <p>Free and open source under Apache 2.0.</p>
        <div>
          <a href={`${github}/blob/main/PRIVACY.md`}>Privacy</a>
          <a href={`${github}/blob/main/SECURITY.md`}>Security</a>
          <a href={releasePage}>Release</a>
          <a href={github}>GitHub</a>
        </div>
        <small>
          WHOOP is a trademark of WHOOP, Inc. WhoopScope is independent and is
          not endorsed by WHOOP.
        </small>
      </footer>
    </main>
  );
}

function AppleMark() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="currentColor"
        d="M16.7 12.9c0-2.7 2.2-4 2.3-4.1a5 5 0 0 0-4-2.2c-1.7-.2-3.3 1-4.2 1-.9 0-2.2-1-3.7-1-1.9 0-3.7 1.1-4.7 2.8-2 3.5-.5 8.6 1.4 11.4.9 1.4 2 2.9 3.5 2.8 1.4 0 1.9-.9 3.6-.9 1.7 0 2.2.9 3.7.9 1.5 0 2.5-1.4 3.4-2.7a12.4 12.4 0 0 0 1.6-3.3 4.7 4.7 0 0 1-2.9-4.7ZM13.9 4.8A4.7 4.7 0 0 0 15 1.4a4.8 4.8 0 0 0-3.1 1.6 4.4 4.4 0 0 0-1.1 3.2 4 4 0 0 0 3.1-1.4Z"
      />
    </svg>
  );
}

function GitHubMark() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="currentColor"
        d="M12 1.5A10.7 10.7 0 0 0 8.6 22.4c.5.1.7-.2.7-.5v-2c-2.9.6-3.5-1.2-3.5-1.2-.5-1.2-1.2-1.5-1.2-1.5-1-.7.1-.7.1-.7 1.1.1 1.7 1.1 1.7 1.1 1 1.7 2.6 1.2 3 .9.1-.7.4-1.2.7-1.5-2.3-.3-4.8-1.2-4.8-5.3 0-1.2.4-2.1 1.1-2.9-.1-.3-.5-1.4.1-2.8 0 0 .9-.3 3 1.1a10.2 10.2 0 0 1 5.5 0C17.1 5.7 18 6 18 6c.6 1.4.2 2.5.1 2.8.7.8 1.1 1.7 1.1 2.9 0 4.1-2.5 5-4.8 5.3.4.3.7 1 .7 1.9v3c0 .3.2.6.7.5A10.7 10.7 0 0 0 12 1.5Z"
      />
    </svg>
  );
}
