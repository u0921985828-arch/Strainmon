<?php
/**
 * Landrace Hunters — ver la portada de Kuboplay Web sin WordPress.
 *
 * Define lo justo de WordPress y de los dos plugins para poder incluir `kuboplay-web/portada.php`
 * tal cual y guardar su HTML, que luego se abre en Chromium (tools/kubo-portada.js) para mirarlo.
 * Solo sirve para verla: no toca nada del plugin.
 *   php tools/kubo-portada.php <salida.html> [carpeta del plugin]
 *
 * @package landrace-hunters-tools
 */

define( 'ABSPATH', __DIR__ );

$salida = isset( $argv[1] ) ? $argv[1] : 'portada.html';
$plugin = isset( $argv[2] ) ? rtrim( $argv[2], '/' ) : __DIR__ . '/../kuboplay-web';

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

class Kuboplay_Web {
	public static function url() { return 'img-local'; }   // las imágenes, al lado del HTML de prueba
	public static function opts() {
		return array( 'texto' => '', 'ad_top' => '', 'ad_bot' => '', 'owner' => 'Kuboplay' );
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
