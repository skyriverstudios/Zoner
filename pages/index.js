import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import clsx from "clsx";
import React from "react";
import styles from "./index.module.css";

const FEATURES = [
  {
    title: "Parallel Zone Engine",
    description:
      "Zoner introduces a new core architecture for zone queries—enabling thousands of zones to run concurrently with minimal performance overhead. Parallel detection can significantly increase scalability. It however can be disabled to run all Zones in serial. With additional functionality to allow for manually stepping Zone detection.",
  },
  {
    title: "Inspired by ZonePlus, Rebuilt from Scratch",
    description:
      "Zoner is not a fork of ZonePlus, but a modern re-imagining built entirely from the ground up. It takes inspiration from ZonePlus’ ideas while evolving its structure, flexibility, and performance for modern Luau workflows.",
  },
  {
    title: "Typed, Documented, and Modular",
    description:
      "Fully typed in Luau and developed through Rojo for structured, modular organization. Every public method is documented inline and auto-generated through Moonwave for developer clarity.",
  },
  {
    title: "Highly Customizable Detection",
    description:
      "Each Zone instance offers deep configurability—choose between multiple detection modes, shapes, and tags. Over 100 possible combinations of behavior and performance tuning.",
  },
  {
    title: "Networking-Aware Design",
    description:
      "Includes an optional lightweight injection system for a RemoteEvent and CollisionGroup, preserving functionality under Streaming Enabled while keeping detection smooth and predictable.",
  },
  {
    title: "Production-Ready Foundation",
    description:
      "Zoner provides a strong and extensible base for any game needing complex zone logic or high-frequency spatial queries.",
  },
];

function Feature({ title, description }) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FEATURES.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  const bannerImage = siteConfig.customFields.bannerImage;
  const hasBannerImage = !!bannerImage;
  const heroBannerStyle = hasBannerImage
    ? { backgroundImage: `url("${bannerImage}")` }
    : null;

  return (
    <header className={clsx("hero", styles.heroBanner)} style={heroBannerStyle}>
      <div className="container">
        <div style={{ textAlign: "center", marginTop: "2rem" }}>
          <img
            alt="Zoner Logo"
            src="/docs/Zoner/Zoner_Repo_Thumbnail.png"
            width="1000"
            style={{
              maxWidth: "95%",
              borderRadius: "5px",
              boxShadow: "0 4px 12px rgba(0,0,0,0.2)",
            }}
          />
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const { siteConfig, tagline } = useDocusaurusContext();
  return (
    <Layout title={siteConfig.title} description={tagline}>
      <HomepageHeader />
      <main>
        <div className="container">
          <div style={{ textAlign: "center", padding: "3rem 1rem" }}>
            <p style={{ fontSize: "1.15rem", opacity: 0.9 }}>
              Zoner is a comprehensive, modern Zone Query module for Roblox
              Luau—rebuilt from scratch as a successor inspired by ZonePlus.
              It provides a typed, documented, and performance-focused framework
              for building advanced spatial systems.
            </p>

            <div
              style={{
                marginTop: "1.25rem",
                display: "flex",
                gap: "0.75rem",
                justifyContent: "center",
                flexWrap: "wrap",
              }}
            >
              <Link
                className="button button--primary"
                style={{
                  backgroundColor: "#6e99dd",
                  borderColor: "#6e99dd",
                  color: "#fff",
                  padding: "0.6rem 1.4rem",
                  fontWeight: 600,
                  display: "inline-flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
                to="/docs/Zoner/api/"
              >
                API Reference
              </Link>
              <Link
                className="button button--secondary"
                style={{
                  padding: "0.6rem 1.4rem",
                  fontWeight: 600,
                  display: "inline-flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
                to="https://github.com/skyriverstudios/Zoner"
              >
                View on GitHub
              </Link>
            </div>
          </div>

          <HomepageFeatures />

          <section
            style={{
              marginTop: "2rem",
              textAlign: "center",
            }}
          >
            <h3>Additional Links</h3>
            <ul style={{ listStyle: "none", padding: 0 }}>
              <li>
                <Link to="https://www.roblox.com/games/105253327037689/Zoner-Playground">
                  Roblox Uncopylocked Playground
                </Link>
              </li>
              <li>
                <Link to="https://create.roblox.com/store/asset/70548782318425/Zoner">
                  Roblox Marketplace Asset
                </Link>
              </li>
            </ul>
          </section>
        </div>
      </main>
    </Layout>
  );
}
