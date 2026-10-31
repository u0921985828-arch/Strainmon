<?php
/**
 * Landrace Hunters — ver la portada de Kuboplay Web sin WordPress.
 *
 * Define lo justo de WordPress y de los dos plugins para poder incluir `wolfcade-web/portada.php`
 * tal cual y guardar su HTML, que luego se abre en Chromium (tools/kubo-portada.js) para mirarlo.
 * Solo sirve para verla: no toca nada del plugin.
 *   php tools/kubo-portada.php <salida.html> [carpeta del plugin] [sin-anuncios]
 *
 * @package landrace-hunters-tools
 */

define( 'ABSPATH', __DIR__ );

$salida = isset( $argv[1] ) ? $argv[1] : 'portada.html';
$plugin = isset( $argv[2] ) ? rtrim( $argv[2], '/' ) : __DIR__ . '/../wolfcade-web';
// con cuadros en el sitio de cada anuncio, para ver que caben; «sin-anuncios» los quita
$GLOBALS['kpw_demo_ads'] = ! in_array( 'sin-anuncios', $argv, true );

function esc_url( $u ) { return htmlspecialchars( $u, ENT_QUOTES ); }
function esc_html( $t ) { return htmlspecialchars( $t, ENT_QUOTES ); }
function esc_attr( $t ) { return htmlspecialchars( $t, ENT_QUOTES ); }
function home_url( $p = '/' ) { return 'https://ejemplo.test' . $p; }
function trailingslashit( $s ) { return rtrim( $s, '/' ) . '/'; }
function wp_strip_all_tags( $t ) { return strip_tags( $t ); }
function wp_trim_words( $t, $n = 55, $mas = '…' ) {
	$p = preg_split( '/\s+/', trim( $t ) );
	return count( $p ) <= $n ? implode( ' ', $p ) : implode( ' ', array_slice( $p, 0, $n ) ) . $mas;
}
function get_bloginfo( $k = 'name' ) { return 'Kuboplay'; }

class Wolfcade_Web {
	public static function url() { return 'img-local'; }   // las imágenes, al lado del HTML de prueba
	public static function opts() {
		return array(
			'texto' => '', 'owner' => 'WOLFCADE',
			// los cuatro huecos, con un cuadro de ejemplo para ver que caben
			'ad_top' => $GLOBALS['kpw_demo_ads'] ? '<div style="width:728px;max-width:100%;height:90px;background:#232a46;color:#8ea;display:grid;place-items:center">728×90</div>' : '',
			'ad_mid' => $GLOBALS['kpw_demo_ads'] ? '<div style="width:336px;height:280px;max-width:100%;margin:0 auto;background:#232a46;color:#8ea;display:grid;place-items:center">336×280</div>' : '',
			'ad_side' => $GLOBALS['kpw_demo_ads'] ? '<div style="width:300px;height:600px;max-width:100%;margin:0 auto;background:#232a46;color:#8ea;display:grid;place-items:center">300×600</div>' : '',
			'ad_bot' => $GLOBALS['kpw_demo_ads'] ? '<div style="width:300px;height:250px;max-width:100%;margin:0 auto;background:#232a46;color:#8ea;display:grid;place-items:center">300×250</div>' : '',
		);
	}
	public static function legal_links() {
		return array( array( 'Aviso legal', home_url( '/aviso-legal/' ) ), array( 'Privacidad', home_url( '/privacidad/' ) ) );
	}
}

class Landrace_Hunters {
	public static function opt( $k ) { return 'title' === $k ? 'Landrace Hunters' : ''; }
	public static function play_url() { return home_url( '/landrace-hunters/' ); }
	public static function game_url() { return home_url( '/juego' ); }
}

ob_start();
include $plugin . '/portada.php';
file_put_contents( $salida, ob_get_clean() );
echo "portada: $salida\n";
