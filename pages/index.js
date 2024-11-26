import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import clsx from "clsx";
import React from "react";
import styles from "./index.module.css";

const FEATURES = [
	{
		title: "Library Agnostic",
		description: <>It does not matter what ECS library you are using, this scheduler is agnostic!</>,
	},
	{
		title: "Designed to be Ergonomic",
		description: (
			<>
				<p>The API for this library is designed to be ergonomic, and allow for a great developer experience.</p>
				<p>It's fully typed, allowing for strict typing and great intellisense.</p>
			</>
		),
	},
	{
		title: "Inspired by Flecs and Bevy",
		description: (
			<>
				This library takes inspiration from Flecs for Phases and Pipelines, and Bevy Schedules for the API
				design.
			</>
		),
	},
];

function FeatureIcon({ icon }) {
	return <div className={styles["feature-icon"]}>{icon}</div>;
}

function Feature({ title, description }) {
	return (
		<div class="col margin-bottom--lg">
			<div class="card">
				<div class="card__header">
					<h2>{title}</h2>
				</div>
				<div class="card__body">{description}</div>
			</div>
		</div>
	);
}

function HomepageFeatures() {
	return (
		<div className="container">
			<div class="row">
				{FEATURES.map((props, idx) => (
					<Feature key={idx} {...props} />
				))}
			</div>
		</div>
	);
}

function HeroBanner() {
	const { siteConfig } = useDocusaurusContext();

	return (
		<div class="hero hero--primary" style={{ height: "25rem", marginBottom: "5rem" }}>
			<div class="container">
				<h1 class="hero__title" style={{ color: "var(--ifm-color-secondary)" }}>
					{siteConfig.title}
				</h1>
				<p class="hero__subtitle" style={{ color: "var(--ifm-color-secondary)" }}>
					{siteConfig.tagline}
				</p>
				<div>
					<Link class="button button--secondary button--lg" style={{ marginRight: "1rem" }} to="/docs/intro">
						<span class={styles["hero-button-text"]}>Get Started</span>
					</Link>
					<Link
						class="button button--outline button--secondary button--lg hero-button"
						style={{ marginRight: "1rem" }}
						to="/api"
					>
						<span class={styles["hero-button-text"]}>API</span>
					</Link>
				</div>
			</div>
		</div>
	);
}

export default function Homepage() {
	const { siteConfig } = useDocusaurusContext();
	return (
		<Layout title={siteConfig.title} description={siteConfig.tagline}>
			<main>
				<HeroBanner />
				<HomepageFeatures />
			</main>
		</Layout>
	);
}
