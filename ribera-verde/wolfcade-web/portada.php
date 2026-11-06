<?php
/**
 * Portada: Landrace Hunters con su botón de jugar, aviso +18 y huecos de anuncios.
 * Página propia (ignora el tema), como la del juego.
 *
 * @package wolfcade-web
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$kpw_o     = Wolfcade_Web::opts();
$kpw_title = Landrace_Hunters::opt( 'title' ) ? Landrace_Hunters::opt( 'title' ) : 'Landrace Hunters';
$kpw_play  = Landrace_Hunters::play_url();
$kpw_icon  = trailingslashit( Landrace_Hunters::game_url() ) . 'icon-576.png';
$kpw_text  = $kpw_o['texto'] ? $kpw_o['texto'] : 'Un RPG de barrio en pixel art: cultiva tus propias variedades, crúzalas para conseguir genética única, véndelas en los clubs y esquiva a la policía y a los rivales. Gratis, en el navegador, sin descargas y con la partida guardada en tu dispositivo.';
$kpw_desc  = wp_strip_all_tags( $kpw_text );
$kpw_ads   = array_filter( array( 'top' => $kpw_o['ad_top'], 'mid' => $kpw_o['ad_mid'], 'side' => $kpw_o['ad_side'], 'bot' => $kpw_o['ad_bot'] ) );
$kpw_owner = $kpw_o['owner'] ? $kpw_o['owner'] : 'WOLFCADE';
$kpw_img   = trailingslashit( Wolfcade_Web::url() ) . 'img/';   // 1.1.0: los sprites del juego, en pixel art

$kpw_ad = static function ( $where ) use ( $kpw_ads ) {
	if ( empty( $kpw_ads[ $where ] ) ) {
		return;
	}
	// El código va dentro de <template>: el navegador no lo ejecuta hasta que el visitante
	// acepta las cookies y kpw() lo pasa a la página.
	echo '<aside class="kpw-ad" data-kpw-ad="' . esc_attr( $where ) . '"><span class="kpw-adl">Publicidad</span><div class="kpw-slot"></div>'
		. '<template>' . $kpw_ads[ $where ] . '</template></aside>'; // phpcs:ignore WordPress.Security.EscapeOutput -- código del anuncio, puesto por el administrador
};
?><!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title><?php echo esc_html( $kpw_title ); ?> · Juego gratis en el navegador (+18)</title>
<meta name="description" content="<?php echo esc_attr( wp_trim_words( $kpw_desc, 30, '…' ) ); ?>">
<meta name="rating" content="adult">
<meta name="theme-color" content="#0b0f1e">
<link rel="canonical" href="<?php echo esc_url( home_url( '/' ) ); ?>">
<link rel="icon" href="<?php echo esc_url( $kpw_icon ); ?>">
<meta property="og:type" content="website">
<meta property="og:title" content="<?php echo esc_attr( $kpw_title ); ?>">
<meta property="og:description" content="<?php echo esc_attr( wp_trim_words( $kpw_desc, 30, '…' ) ); ?>">
<meta property="og:image" content="<?php echo esc_url( $kpw_icon ); ?>">
<meta property="og:url" content="<?php echo esc_url( home_url( '/' ) ); ?>">
<style>
:root{--kpw-hoja:url("<?php echo esc_url( $kpw_img . 'hoja.png' ); ?>");--bg:#0b0f1e;--card:#141a30;--ink:#eef1ff;--mute:#a3abd0;--ac:#4fae5a;--ac2:#8fdc7a;--ln:#1a1530}
*{box-sizing:border-box}
body{margin:0;background:radial-gradient(120% 70% at 50% -10%,#1d3a26 0,var(--bg) 60%) fixed,var(--bg);color:var(--ink);font:16px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif}
main{max-width:860px;margin:0 auto;padding:8px 0 24px}
.kpw-hero{position:relative;display:grid;grid-template-columns:minmax(0,1fr);justify-items:center;text-align:center;gap:12px;padding:18px 0 8px}
.kpw-hero>img.kpw-ico{width:148px;height:148px;image-rendering:pixelated;border-radius:28px;border:3px solid var(--ln);box-shadow:0 10px 0 rgba(0,0,0,.35),0 0 0 6px rgba(79,174,90,.18)}
/* 1.1.0: el rótulo del juego, su gente y su barrio, en los mismos píxeles que dentro */
.kpw-logo{width:min(560px,92%);height:auto;image-rendering:pixelated;filter:drop-shadow(0 6px 0 rgba(0,0,0,.45))}
.kpw-sr{position:absolute;width:1px;height:1px;margin:-1px;padding:0;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0}
.kpw-esc{position:relative;display:flex;align-items:flex-end;justify-content:center;gap:clamp(10px,5vw,40px);width:100%;max-width:560px;margin:4px auto 0;padding-bottom:12px}
.kpw-esc img{width:auto;image-rendering:pixelated;filter:drop-shadow(0 5px 0 rgba(0,0,0,.4))}
.kpw-esc .e1{height:clamp(96px,26vw,150px)}.kpw-esc .e2{height:clamp(66px,18vw,104px)}.kpw-esc .e3{height:clamp(76px,21vw,120px)}
.kpw-esc::after{content:"";position:absolute;left:4%;right:4%;bottom:0;height:3px;border-radius:3px;background:linear-gradient(90deg,transparent,rgba(79,174,90,.6),transparent)}
h1{margin:6px 0 0;font-size:clamp(30px,8vw,50px);line-height:1.05;letter-spacing:-.01em}
.kpw-tag{margin:0;color:var(--ac2);font-weight:600}
.kpw-18{display:inline-flex;align-items:center;gap:8px;margin:2px 0 0;padding:4px 12px;border-radius:99px;border:1px solid rgba(255,255,255,.18);color:var(--mute);font-size:14px}
.kpw-18 b{display:inline-grid;place-items:center;width:30px;height:30px;border-radius:50%;background:#c2413a;color:#fff;font-size:12px}
.kpw-play{display:inline-flex;align-items:center;justify-content:center;gap:10px;min-height:58px;margin-top:8px;padding:0 30px;border-radius:16px;border:3px solid var(--ln);background:var(--ac);color:#08130a;font-weight:800;font-size:20px;text-decoration:none;box-shadow:0 6px 0 #2c6e35}
.kpw-play:active{transform:translateY(4px);box-shadow:0 2px 0 #2c6e35}
.kpw-play svg{width:22px;height:22px}
.kpw-note{margin:0;color:var(--mute);font-size:13.5px;max-width:420px}
.kpw-txt{max-width:640px;margin:18px auto 0;color:var(--ink);text-align:center}
.kpw-feat{list-style:none;margin:22px 0 0;padding:0;display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,220px),1fr));gap:12px}
.kpw-feat li{position:relative;background:var(--card);border:1px solid rgba(255,255,255,.07);border-radius:14px;padding:14px 16px;overflow:hidden}
.kpw-feat li::after{content:"";position:absolute;right:-14px;bottom:-14px;width:84px;height:80px;background:var(--kpw-hoja) center/contain no-repeat;opacity:.09;pointer-events:none}
.kpw-feat strong{display:block;color:var(--ac2);margin-bottom:2px}
.kpw-feat span{color:var(--mute);font-size:14.5px}
.kpw-ad{margin:22px auto 0;width:100%;max-width:100%;text-align:center;overflow:hidden;contain:inline-size}
.kpw-ad[hidden]{display:none}
.kpw-adl{display:block;margin-bottom:4px;color:var(--mute);font-size:11px;letter-spacing:.08em;text-transform:uppercase}
.kpw-slot{display:flex;justify-content:center;align-items:flex-start;width:100%;max-width:100%;overflow:hidden}
.kpw-slot>*{max-width:100%}
.kpw-slot img,.kpw-slot iframe,.kpw-slot ins{max-width:100%;height:auto}
.kpw-slot img{max-width:100%;height:auto}
/* 1.2.0: la marca de la casa, las capturas del juego y la columna de anuncios */
.kpw-top{position:sticky;top:0;z-index:40;display:flex;align-items:center;justify-content:center;gap:9px;padding:9px 16px calc(9px);background:rgba(10,14,28,.86);backdrop-filter:blur(8px);border-bottom:1px solid rgba(255,255,255,.08)}
.kpw-top b{font:800 15px/1 system-ui,sans-serif;letter-spacing:.14em;text-transform:uppercase;color:var(--ink)}
.kpw-top b i{font-style:normal;color:var(--ac2)}
.kpw-top svg{width:24px;height:24px;color:var(--ac2)}
.kpw-wrap>*{min-width:0}   /* un anuncio ancho no estira la columna en el móvil */
.kpw-wrap{display:grid;grid-template-columns:minmax(0,1fr);gap:18px;max-width:1220px;margin:0 auto;padding:0 16px}
@media (min-width:1080px){.kpw-wrap{grid-template-columns:minmax(0,860px) 300px;justify-content:center;align-items:start}.kpw-col{position:sticky;top:60px}}
.kpw-col{margin:22px 0 0;text-align:center}
.kpw-badges{display:flex;flex-wrap:wrap;justify-content:center;gap:8px;margin:0;padding:0;list-style:none}
.kpw-badges li{padding:4px 11px;border-radius:99px;background:rgba(79,174,90,.14);border:1px solid rgba(79,174,90,.35);color:var(--ac2);font-size:13px;font-weight:600}
.kpw-play{animation:kpw-pulso 2.6s ease-in-out infinite}
@keyframes kpw-pulso{0%,100%{box-shadow:0 6px 0 #2c6e35,0 0 0 0 rgba(79,174,90,.45)}50%{box-shadow:0 6px 0 #2c6e35,0 0 0 14px rgba(79,174,90,0)}}
@media (prefers-reduced-motion:reduce){.kpw-play{animation:none}}
.kpw-caps{margin:26px 0 0}
.kpw-caps h2{margin:0 0 10px;text-align:center;font-size:19px}
.kpw-caps div{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,300px),1fr));gap:12px}
.kpw-caps img{width:100%;height:auto;display:block;border-radius:12px;border:1px solid rgba(255,255,255,.1);box-shadow:0 8px 24px rgba(0,0,0,.45)}
footer{max-width:860px;margin:30px auto 0;padding:18px 16px calc(24px + env(safe-area-inset-bottom));border-top:1px solid rgba(255,255,255,.08);color:var(--mute);font-size:14px;display:flex;flex-wrap:wrap;gap:8px 18px;justify-content:center}
footer a,footer button{color:var(--mute);font:inherit;background:none;border:0;padding:0;cursor:pointer;text-decoration:underline;text-underline-offset:3px;min-height:32px}
#kpw-ck{position:fixed;left:50%;bottom:calc(12px + env(safe-area-inset-bottom));transform:translateX(-50%);z-index:50;width:min(560px,calc(100vw - 24px));padding:14px 16px;border-radius:16px;background:#151b33;border:1px solid rgba(255,255,255,.16);box-shadow:0 10px 30px rgba(0,0,0,.55);font-size:14.5px}
#kpw-ck[hidden]{display:none}
#kpw-ck p{margin:0 0 10px}
#kpw-ck div{display:flex;gap:10px;flex-wrap:wrap}
#kpw-ck button{flex:1 1 140px;min-height:46px;border-radius:12px;border:0;font:700 15px system-ui,sans-serif;cursor:pointer}
#kpw-ck .ok{background:var(--ac);color:#08130a}
#kpw-ck .no{background:transparent;color:var(--ink);border:1px solid rgba(255,255,255,.25)}
</style>
</head>
<body>
<header class="kpw-top">
	<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round">
		<path d="M4 20V9l4-5 1.5 3h5L16 4l4 5v11z"/><path d="M9.5 20v-4a2.5 2.5 0 0 1 5 0v4"/>
	</svg>
	<b>WOLF<i>CADE</i></b>
</header>
<div class="kpw-wrap">
<main>
	<section class="kpw-hero">
		<img class="kpw-logo" src="<?php echo esc_url( $kpw_img . 'logo.png' ); ?>" width="1792" height="532"
			alt="<?php echo esc_attr( $kpw_title ); ?>" fetchpriority="high">
		<h1 class="kpw-sr"><?php echo esc_html( $kpw_title ); ?></h1>
		<p class="kpw-tag">Genética de barrio · cultiva, cruza y vende</p>
		<p class="kpw-18"><b>+18</b> Solo para mayores de edad</p>
		<a class="kpw-play" href="<?php echo esc_url( $kpw_play ); ?>"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 4.5v15l12-7.5z" fill="currentColor"/></svg>Tengo 18 años · Jugar</a>
		<ul class="kpw-badges"><li>Gratis</li><li>Sin descargas</li><li>Móvil y ordenador</li><li>Partida guardada</li></ul>
		<p class="kpw-note">Gratis, en el navegador, sin registro. Es un juego de ficción: no vende ni ofrece ninguna sustancia.</p>
		<div class="kpw-esc" aria-hidden="true">
			<img class="e1" src="<?php echo esc_url( $kpw_img . 'club.png' ); ?>" width="330" height="490" alt="" loading="lazy">
			<img class="e2" src="<?php echo esc_url( $kpw_img . 'protagonista.png' ); ?>" width="342" height="551" alt="" loading="lazy">
			<img class="e3" src="<?php echo esc_url( $kpw_img . 'planta.png' ); ?>" width="418" height="528" alt="" loading="lazy">
		</div>
	</section>
	<?php $kpw_ad( 'top' ); ?>
	<p class="kpw-txt"><?php echo esc_html( $kpw_text ); ?></p>
	<ul class="kpw-feat">
		<li><strong>Cultiva y cruza</strong><span>Semillas, esquejes y madres: consigue variedades que nadie más tiene.</span></li>
		<li><strong>Un barrio vivo</strong><span>Clubs, tiendas, el puerto y Bilbao por dentro, con día, noche y clima.</span></li>
		<li><strong>Móvil u ordenador</strong><span>Mando táctil en el móvil y teclado o ratón en el ordenador. Se puede instalar como app.</span></li>
	</ul>
	<section class="kpw-caps">
		<h2>Así se juega</h2>
		<div>
			<img src="<?php echo esc_url( $kpw_img . 'cap-plaza.jpg' ); ?>" width="960" height="540" alt="La plaza del barrio, con gente, la fuente y los clientes esperando" loading="lazy">
			<img src="<?php echo esc_url( $kpw_img . 'cap-club.jpg' ); ?>" width="960" height="540" alt="Un club por dentro, con sus sofás, el dispensario y la mesa de billar" loading="lazy">
		</div>
	</section>
	<?php $kpw_ad( 'mid' ); ?>
	<?php $kpw_ad( 'bot' ); ?>
</main>
<aside class="kpw-col"><?php $kpw_ad( 'side' ); ?></aside>
</div>
<footer>
	<span>© <?php echo esc_html( gmdate( 'Y' ) . ' ' . $kpw_owner ); ?></span>
	<?php foreach ( Wolfcade_Web::legal_links() as $kpw_l ) : ?>
		<a href="<?php echo esc_url( $kpw_l[1] ); ?>"><?php echo esc_html( $kpw_l[0] ); ?></a>
	<?php endforeach; ?>
	<?php if ( $kpw_ads ) : ?>
		<button type="button" id="kpw-pref">Preferencias de cookies</button>
	<?php endif; ?>
</footer>
<?php if ( $kpw_ads ) : ?>
<div id="kpw-ck" role="dialog" aria-label="Cookies" hidden>
	<p>Usamos cookies de terceros para mostrar anuncios, que es lo que mantiene el juego gratis. Sin tu permiso no se carga ninguno.</p>
	<div><button type="button" class="no" data-v="0">Rechazar</button><button type="button" class="ok" data-v="1">Aceptar</button></div>
</div>
<script>
(function () {
	var K = 'kpw-consent', ck = document.getElementById('kpw-ck'), done = false;
	function get() { try { return localStorage.getItem(K); } catch (e) { return null; } }
	function put(v) { try { localStorage.setItem(K, v); } catch (e) {} }
	// Pasa el código de cada <template> a la página. Cada <script> se crea de nuevo antes de
	// insertarlo (con sus atributos y su texto), así se ejecuta una vez en todos los navegadores.
	function load() {
		if (done) return; done = true;
		document.querySelectorAll('[data-kpw-ad]').forEach(function (box) {
			var tpl = box.querySelector('template'), slot = box.querySelector('.kpw-slot');
			if (!tpl || !slot) return;
			var frag = document.importNode(tpl.content, true);
			frag.querySelectorAll('script').forEach(function (old) {
				var s = document.createElement('script');
				for (var i = 0; i < old.attributes.length; i++) s.setAttribute(old.attributes[i].name, old.attributes[i].value);
				s.text = old.text;
				old.parentNode.replaceChild(s, old);
			});
			slot.appendChild(frag);
		});
	}
	function hideAds(h) { document.querySelectorAll('[data-kpw-ad]').forEach(function (b) { b.hidden = h; }); }
	var v = get();
	if (v === '1') load(); else { hideAds(true); if (v !== '0') ck.hidden = false; }
	ck.addEventListener('click', function (e) {
		var b = e.target.closest('button'); if (!b) return;
		var was = get(); put(b.getAttribute('data-v')); ck.hidden = true;
		if (b.getAttribute('data-v') === '1') { hideAds(false); load(); }
		else if (was === '1') location.reload(); // Retirar el permiso: fuera lo ya cargado.
	});
	document.getElementById('kpw-pref').addEventListener('click', function () { ck.hidden = false; });
})();
</script>
<?php endif; ?>
</body>
</html>
