<?php
/**
 * Plugin Name: Landrace Hunters
 * Description: Hospeda el juego «Landrace Hunters» (Godot 4.3, versión web: la misma partida que la app de Android) dentro de WordPress: dirección propia a pantalla completa y atajo [landrace_hunters] para incrustarlo en cualquier página. Todo se sirve desde el propio plugin.
 * Version: 1.6.5
 * Author: WOLFCADE
 * License: GPL-2.0-or-later
 * Text Domain: landrace-hunters
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Landrace_Hunters {

	const VERSION   = '1.6.5';
	/** El plugin ligero (para servidores que no dejan subir más de unos MB) baja el resto del juego de aquí, en el propio servidor. */
	const FULL_URL  = 'https://raw.githubusercontent.com/u0921985828-arch/Strainmon/claude/new-session-7quvtm/ribera-verde/descargas/landrace-hunters-%s.zip';
	const PIEZAS    = array( 'index.js', 'index.wasm', 'index.pck', 'index.audio.worklet.js', 'index.audio.position.worklet.js' );
	const OPTION    = 'landrace_hunters';
	const QUERY_VAR = 'landrace_hunters';

	/** Valores por defecto de los ajustes. */
	private static function defaults() {
		return array(
			'slug'  => 'landrace-hunters',
			'title' => 'Landrace Hunters',
			'fs'    => 1,
		);
	}

	public static function opt( $key ) {
		$o = wp_parse_args( (array) get_option( self::OPTION, array() ), self::defaults() );
		return isset( $o[ $key ] ) ? $o[ $key ] : '';
	}

	/** Carpeta y URL del juego (todo sale de __FILE__, así que el nombre de la carpeta da igual). */
	public static function game_dir() {
		return __DIR__ . '/game';
	}

	public static function game_url() {
		return plugins_url( 'game', __FILE__ );
	}

	/** ¿Están las piezas grandes del juego? (el plugin ligero no las trae: se descargan desde el panel). */
	public static function game_ready() {
		foreach ( self::PIEZAS as $f ) {
			if ( ! is_readable( self::game_dir() . '/' . $f ) ) {
				return false;
			}
		}
		return true;
	}

	/**
	 * Descarga el zip entero de esta versión en el servidor y copia sus piezas a game/.
	 * Así no hay que subir 30 MB por el navegador (nginx corta con «413 Request Entity Too Large»).
	 */
	public static function fetch_game() {
		if ( ! class_exists( 'ZipArchive' ) ) {
			return new WP_Error( 'lh_zip', 'Este servidor no tiene ZipArchive de PHP. Sube el plugin completo por FTP o por el gestor de archivos.' );
		}
		require_once ABSPATH . 'wp-admin/includes/file.php';
		if ( function_exists( 'set_time_limit' ) ) {
			@set_time_limit( 900 ); // phpcs:ignore WordPress.PHP.NoSilencedErrors
		}
		$tmp = download_url( sprintf( self::FULL_URL, self::VERSION ), 900 );
		if ( is_wp_error( $tmp ) ) {
			return $tmp;
		}
		$zip = new ZipArchive();
		if ( true !== $zip->open( $tmp ) ) {
			@unlink( $tmp ); // phpcs:ignore WordPress.PHP.NoSilencedErrors
			return new WP_Error( 'lh_zip', 'El archivo descargado no es un zip.' );
		}
		$err = null;
		foreach ( array_merge( self::PIEZAS, array( 'index.html' ) ) as $f ) {
			$in  = $zip->getStream( 'landrace-hunters/game/' . $f );
			$out = $in ? fopen( self::game_dir() . '/' . $f . '.part', 'wb' ) : false; // phpcs:ignore WordPress.WP.AlternativeFunctions
			if ( ! $in || ! $out || false === stream_copy_to_stream( $in, $out ) ) {
				$err = new WP_Error( 'lh_copia', 'No se ha podido copiar ' . $f . ' a la carpeta del plugin (¿permisos de escritura?).' );
			}
			if ( $in ) {
				fclose( $in ); // phpcs:ignore WordPress.WP.AlternativeFunctions
			}
			if ( $out ) {
				fclose( $out ); // phpcs:ignore WordPress.WP.AlternativeFunctions
			}
			if ( $err ) {
				break;
			}
			rename( self::game_dir() . '/' . $f . '.part', self::game_dir() . '/' . $f );
		}
		$zip->close();
		@unlink( $tmp ); // phpcs:ignore WordPress.PHP.NoSilencedErrors
		if ( $err ) {
			return $err;
		}
		return self::game_ready() ? true : new WP_Error( 'lh_faltan', 'Faltan piezas del juego tras la descarga.' );
	}

	/** El botón del panel y del aviso. */
	public static function descargar() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Sin permiso.', 'landrace-hunters' ) );
		}
		check_admin_referer( 'lh_descargar' );
		$r = self::fetch_game();
		$q = true === $r ? array( 'lh' => 'ok' ) : array( 'lh' => 'error', 'lh_msg' => rawurlencode( $r->get_error_message() ) );
		wp_safe_redirect( add_query_arg( $q, admin_url( 'options-general.php?page=landrace-hunters' ) ) );
		exit;
	}

	private static function boton_descargar( $clase = 'button button-primary' ) {
		?>
		<form method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" style="display:inline">
			<input type="hidden" name="action" value="lh_descargar">
			<?php wp_nonce_field( 'lh_descargar' ); ?>
			<button type="submit" class="<?php echo esc_attr( $clase ); ?>" onclick="this.disabled=true;this.textContent='Descargando… (hasta un par de minutos)';this.form.submit()">Descargar el juego (unos 30 MB)</button>
		</form>
		<?php
	}

	public static function aviso() {
		if ( self::game_ready() || ! current_user_can( 'manage_options' ) || ( isset( $_GET['page'] ) && 'landrace-hunters' === $_GET['page'] ) ) { // phpcs:ignore WordPress.Security.NonceVerification
			return;
		}
		echo '<div class="notice notice-warning"><p><strong>Landrace Hunters:</strong> falta descargar el juego en el servidor (el plugin ligero no lo trae). ';
		self::boton_descargar( 'button' );
		echo '</p></div>';
	}

	public static function game_file() {
		return self::game_dir() . '/index.html';
	}

	/** Dirección pública del juego: bonita si hay enlaces permanentes, con parámetro si no. */
	public static function play_url( $args = array() ) {
		$slug = self::opt( 'slug' );
		if ( get_option( 'permalink_structure' ) && $slug ) {
			$url = home_url( '/' . $slug . '/' );
		} else {
			$url = add_query_arg( self::QUERY_VAR, 1, home_url( '/' ) );
		}
		return $args ? add_query_arg( $args, $url ) : $url;
	}

	public static function init() {
		add_action( 'init', array( __CLASS__, 'rewrite' ) );
		add_action( 'init', array( __CLASS__, 'maybe_upgrade' ), 20 );
		add_filter( 'query_vars', array( __CLASS__, 'query_vars' ) );
		add_action( 'template_redirect', array( __CLASS__, 'maybe_serve' ) );
		add_shortcode( 'landrace_hunters', array( __CLASS__, 'shortcode' ) );
		add_action( 'admin_menu', array( __CLASS__, 'menu' ) );
		add_action( 'admin_init', array( __CLASS__, 'settings' ) );
		add_action( 'admin_post_lh_descargar', array( __CLASS__, 'descargar' ) );
		add_action( 'admin_notices', array( __CLASS__, 'aviso' ) );
		add_filter( 'plugin_action_links_' . plugin_basename( __FILE__ ), array( __CLASS__, 'action_links' ) );
	}

	public static function rewrite() {
		$slug = self::opt( 'slug' );
		if ( $slug ) {
			add_rewrite_rule( '^' . preg_quote( $slug, '/' ) . '/?$', 'index.php?' . self::QUERY_VAR . '=1', 'top' );
		}
	}

	/**
	 * Al subir una versión nueva («Reemplazar actual con el subido») no se ejecuta la activación.
	 * La primera visita tras el cambio vacía la caché de página de Kuboplay Shield, si está,
	 * para que nadie se quede con la página vieja guardada de antes.
	 */
	public static function maybe_upgrade() {
		if ( get_option( self::OPTION . '_ver' ) === self::VERSION ) {
			return;
		}
		update_option( self::OPTION . '_ver', self::VERSION, false );
		do_action( 'kp_shield_purge' );
	}

	public static function query_vars( $vars ) {
		$vars[] = self::QUERY_VAR;
		return $vars;
	}

	/** Al activar y al cambiar el slug hay que reescribir las reglas; si no, la dirección da 404. */
	public static function activate() {
		self::rewrite();
		flush_rewrite_rules();
	}

	/** Al borrar el plugin no deja nada en la base de datos. */
	public static function uninstall() {
		delete_option( self::OPTION );
		delete_option( self::OPTION . '_ver' );
	}

	public static function deactivate() {
		// flush_rewrite_rules() volvería a guardar la regla, que ya se registró en init:
		// se borran y WordPress las rehace en la siguiente visita, ya sin el plugin.
		delete_option( 'rewrite_rules' );
	}

	/**
	 * Sirve el juego en su dirección propia.
	 *
	 * Es la exportación web de Godot tal cual: un HTML que carga index.js, index.wasm e
	 * index.pck por ruta relativa. Se le añade un <base> apuntando a la carpeta del plugin
	 * para que esas rutas sigan valiendo aunque la página viva en /landrace-hunters/.
	 */
	public static function maybe_serve() {
		$q = get_query_var( self::QUERY_VAR );
		if ( ! $q ) {
			return;
		}
		if ( 'manifest' === $q ) {
			self::manifest();
		}
		// La página ya lleva su propia ETag y 304. Que ninguna caché de página (Kuboplay Shield)
		// la guarde horas: al actualizar el plugin se seguiría sirviendo el HTML viejo.
		if ( ! defined( 'DONOTCACHEPAGE' ) ) {
			define( 'DONOTCACHEPAGE', true );
		}

		$file = self::game_file();
		if ( is_readable( $file ) && ! self::game_ready() ) {
			status_header( 503 );
			wp_die( esc_html__( 'Falta descargar el juego: en el escritorio de WordPress, Ajustes → Landrace Hunters → «Descargar el juego».', 'landrace-hunters' ) );
		}
		if ( ! is_readable( $file ) ) {
			status_header( 500 );
			wp_die( esc_html__( 'No encuentro el juego dentro del plugin.', 'landrace-hunters' ) );
		}

		$html = file_get_contents( $file ); // phpcs:ignore WordPress.WP.AlternativeFunctions
		$base = '<base href="' . esc_url( trailingslashit( self::game_url() ) ) . '">';
		$html = preg_replace( '#(<meta\s+charset="utf-8">)#i', '$1' . "\n\t\t" . $base, $html, 1 );
		$html = preg_replace( '#<title>[^<]*</title>#i', '<title>' . esc_html( self::opt( 'title' ) ) . '</title>', $html, 1 );
		if ( self::opt( 'fs' ) ) {
			$html = self::fullscreen( $html );
		}

		$etag = '"' . md5( $html . self::VERSION ) . '"';

		nocache_headers();
		header_remove( 'Expires' );
		header_remove( 'Pragma' );
		header( 'Content-Type: text/html; charset=utf-8' );
		header( 'Cache-Control: public, max-age=600' );
		header( 'ETag: ' . $etag );
		header( 'X-Frame-Options: SAMEORIGIN' );

		$sent = isset( $_SERVER['HTTP_IF_NONE_MATCH'] ) ? trim( wp_unslash( $_SERVER['HTTP_IF_NONE_MATCH'] ) ) : '';
		if ( $sent && false !== strpos( $sent, trim( $etag, '"' ) ) ) {
			status_header( 304 );
			exit;
		}

		status_header( 200 );
		echo $html; // phpcs:ignore WordPress.Security.EscapeOutput
		exit;
	}

	/**
	 * Pantalla completa sin barra del navegador.
	 *
	 * Ningún navegador deja quitar la barra sin que el jugador toque algo, así que lh-fs.js
	 * pide la pantalla completa (y gira a horizontal) con el primer toque, clic o tecla.
	 * Además la página se puede instalar («Añadir a pantalla de inicio»): abierta desde el
	 * icono va sin barra desde el principio. Es la única vía en iPhone, que no tiene
	 * pantalla completa para páginas web.
	 */
	private static function fullscreen( $html ) {
		$title = esc_attr( self::opt( 'title' ) );
		$icon  = esc_url( trailingslashit( self::game_url() ) . 'icon-192.png' );
		$man   = esc_url( add_query_arg( self::QUERY_VAR, 'manifest', home_url( '/' ) ) );

		$html = str_replace( 'initial-scale=1.0">', 'initial-scale=1.0, viewport-fit=cover">', $html );

		$head  = "\t\t<meta name=\"theme-color\" content=\"#000000\">\n";
		$head .= "\t\t<meta name=\"mobile-web-app-capable\" content=\"yes\">\n";
		$head .= "\t\t<meta name=\"apple-mobile-web-app-capable\" content=\"yes\">\n";
		$head .= "\t\t<meta name=\"apple-mobile-web-app-status-bar-style\" content=\"black-translucent\">\n";
		$head .= "\t\t<meta name=\"apple-mobile-web-app-title\" content=\"{$title}\">\n";
		$head .= "\t\t<link rel=\"manifest\" href=\"{$man}\">\n";
		$head .= "\t\t<link rel=\"icon\" href=\"{$icon}\">\n";
		$head .= "\t\t<link rel=\"apple-touch-icon\" href=\"{$icon}\">\n";
		$head .= '<style>#lh-rot{position:fixed;inset:0;z-index:99;display:none;flex-direction:column;align-items:center;justify-content:center;gap:14px;'
			. 'background:#0b0f1e;color:#fff;font:600 20px/1.3 system-ui,sans-serif;text-align:center;padding:24px}'
			. '#lh-rot small{font-weight:400;font-size:15px;opacity:.8;max-width:300px}'
			. '@media (orientation:portrait) and (pointer:coarse){#lh-rot{display:flex}}#lh-rot.off{display:none!important}'
			. '#lh-inst{position:fixed;left:50%;bottom:calc(10px + env(safe-area-inset-bottom));transform:translateX(-50%);z-index:100;display:flex;align-items:center;gap:10px;'
			. 'width:max-content;max-width:calc(100vw - 20px);box-sizing:border-box;padding:8px 8px 8px 14px;border-radius:14px;background:rgba(11,15,30,.94);'
			. 'border:1px solid rgba(255,255,255,.18);box-shadow:0 6px 24px rgba(0,0,0,.5);color:#fff;font:14px/1.35 system-ui,sans-serif}'
			. '@media (orientation:landscape){#lh-inst{top:calc(8px + env(safe-area-inset-top));bottom:auto;max-width:min(640px,74vw)}}#lh-inst p{margin:0}#lh-inst svg{vertical-align:-3px;color:#4fae5a}#lh-inst.off{display:none}'
			. '#lh-inst button{flex:none;min-height:44px;border:0;border-radius:10px;font:600 15px system-ui,sans-serif;cursor:pointer}'
			. '#lh-inst .lh-go{padding:0 16px;background:#4fae5a;color:#08130a}'
			. '#lh-inst .lh-x{width:44px;background:transparent;color:#fff;font-size:24px;opacity:.75}</style>' . "\n";
		$html  = preg_replace( '#</head>#i', $head . '</head>', $html, 1 );

		$body  = '<div id="lh-rot" role="dialog" aria-label="Gira el móvil">'
			. '<svg width="96" height="96" viewBox="0 0 96 96" aria-hidden="true"><rect x="30" y="14" width="36" height="62" rx="7" fill="none" stroke="#fff" stroke-width="5"/>'
			. '<path d="M14 58a34 34 0 0 0 34 26" fill="none" stroke="#4fae5a" stroke-width="5" stroke-linecap="round"/><path d="M40 78l9 6-6 9" fill="none" stroke="#4fae5a" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/></svg>'
			. '<span>Gira el móvil</span><small>Toca para jugar a pantalla completa.</small></div>' . "\n";
		$body .= '<script src="lh-fs.js?v=' . esc_attr( self::VERSION ) . '"></script>' . "\n";
		$html  = preg_replace( '#</body>#i', $body . '</body>', $html, 1 );

		return $html;
	}

	/** Manifiesto de la app instalable: abre a pantalla completa y en horizontal. */
	private static function manifest() {
		if ( ! defined( 'DONOTCACHEPAGE' ) ) {
			define( 'DONOTCACHEPAGE', true );
		}
		$url  = trailingslashit( self::game_url() );
		$data = array(
			'name'             => self::opt( 'title' ),
			'short_name'       => self::opt( 'title' ),
			'start_url'        => self::play_url(),
			'scope'            => self::play_url(),
			'display'          => 'fullscreen',
			'orientation'      => 'landscape',
			'id'               => self::play_url(),
			'description'      => self::opt( 'title' ),
			'background_color' => '#000000',
			'theme_color'      => '#000000',
			'icons'            => array(
				array( 'src' => $url . 'icon-192.png', 'sizes' => '192x192', 'type' => 'image/png' ),
				array( 'src' => $url . 'icon-576.png', 'sizes' => '576x576', 'type' => 'image/png', 'purpose' => 'any' ),
			),
		);
		status_header( 200 );
		header( 'Content-Type: application/manifest+json; charset=utf-8' );
		header( 'Cache-Control: public, max-age=3600' );
		echo wp_json_encode( $data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ); // phpcs:ignore WordPress.Security.EscapeOutput
		exit;
	}

	/**
	 * [landrace_hunters alto="80vh" texto="Abrir a pantalla completa"]
	 *
	 * Incrusta el juego en una página. El enlace de debajo lo abre en su dirección propia,
	 * que es como se juega bien en el móvil.
	 */
	public static function shortcode( $atts ) {
		$a = shortcode_atts(
			array(
				'alto'  => '80vh',
				'texto' => 'Abrir a pantalla completa',
			),
			$atts,
			'landrace_hunters'
		);

		$alto = preg_match( '/^[0-9.]+(px|vh|vw|%|em|rem)$/', $a['alto'] ) ? $a['alto'] : '80vh';

		$out  = '<div class="lh-embed" style="margin:1.2em 0">';
		$out .= '<iframe src="' . esc_url( self::play_url() ) . '"'
			. ' title="' . esc_attr( self::opt( 'title' ) ) . '"'
			. ' style="display:block;width:100%;height:' . esc_attr( $alto ) . ';border:0;border-radius:10px;background:#000"'
			. ' allow="fullscreen; gamepad; autoplay" allowfullscreen loading="lazy"></iframe>';
		if ( $a['texto'] ) {
			$out .= '<p style="margin:.6em 0 0;text-align:center"><a href="' . esc_url( self::play_url() ) . '" target="_blank" rel="noopener">'
				. esc_html( $a['texto'] ) . '</a></p>';
		}
		$out .= '</div>';

		return $out;
	}

	/* ---------- Panel ---------- */

	public static function action_links( $links ) {
		array_unshift(
			$links,
			'<a href="' . esc_url( admin_url( 'options-general.php?page=landrace-hunters' ) ) . '">' . esc_html__( 'Ajustes', 'landrace-hunters' ) . '</a>',
			'<a href="' . esc_url( self::play_url() ) . '" target="_blank" rel="noopener">' . esc_html__( 'Jugar', 'landrace-hunters' ) . '</a>'
		);
		return $links;
	}

	public static function menu() {
		add_options_page( 'Landrace Hunters', 'Landrace Hunters', 'manage_options', 'landrace-hunters', array( __CLASS__, 'page' ) );
	}

	public static function settings() {
		register_setting(
			'landrace_hunters_group',
			self::OPTION,
			array(
				'type'              => 'array',
				'sanitize_callback' => array( __CLASS__, 'sanitize' ),
				'default'           => self::defaults(),
			)
		);
	}

	public static function sanitize( $in ) {
		$old  = wp_parse_args( (array) get_option( self::OPTION, array() ), self::defaults() );
		$slug = isset( $in['slug'] ) ? sanitize_title( $in['slug'] ) : '';
		$out  = array(
			'slug'  => $slug ? $slug : self::defaults()['slug'],
			'title' => isset( $in['title'] ) ? sanitize_text_field( $in['title'] ) : $old['title'],
			'fs'    => empty( $in['fs'] ) ? 0 : 1,
		);
		if ( $out['slug'] !== $old['slug'] ) {
			// El slug nuevo necesita reglas nuevas; si no, la dirección da 404.
			add_action(
				'shutdown',
				function () {
					flush_rewrite_rules();
				}
			);
		}
		return $out;
	}

	public static function page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			return;
		}
		$url  = self::play_url();
		$size = 0;
		foreach ( array( 'index.wasm', 'index.pck', 'index.js' ) as $f ) {
			$p     = self::game_dir() . '/' . $f;
			$size += is_readable( $p ) ? filesize( $p ) : 0;
		}
		?>
		<div class="wrap">
			<h1>Landrace Hunters</h1>
			<?php
			$lh = isset( $_GET['lh'] ) ? sanitize_key( $_GET['lh'] ) : ''; // phpcs:ignore WordPress.Security.NonceVerification
			if ( 'ok' === $lh ) :
				?>
				<div class="notice notice-success inline"><p>Juego descargado. Ya se puede jugar.</p></div>
			<?php elseif ( 'error' === $lh ) : ?>
				<div class="notice notice-error inline"><p>No se ha podido descargar: <?php echo esc_html( isset( $_GET['lh_msg'] ) ? rawurldecode( sanitize_text_field( wp_unslash( $_GET['lh_msg'] ) ) ) : '' ); // phpcs:ignore WordPress.Security.NonceVerification ?></p></div>
			<?php endif; ?>
			<?php if ( ! self::game_ready() ) : ?>
				<div class="notice notice-warning inline"><p>Es el plugin ligero: el juego (unos 30 MB) se descarga directamente en el servidor, sin subirlo por el navegador.</p>
					<p><?php self::boton_descargar(); ?></p></div>
			<?php endif; ?>
			<p>El juego está dentro del plugin (<?php echo esc_html( size_format( $size ) ); ?>; el navegador lo descarga comprimido la primera vez y luego lo guarda). Se juega aquí:</p>
			<p><a class="button button-primary" href="<?php echo esc_url( $url ); ?>" target="_blank" rel="noopener">Jugar ahora</a>
				&nbsp;<code><?php echo esc_html( $url ); ?></code></p>
			<p>Para ponerlo dentro de una página o entrada, pega este atajo:</p>
			<p><code>[landrace_hunters]</code> &nbsp;— o con la altura que quieras: <code>[landrace_hunters alto="600px"]</code></p>
			<?php if ( ! get_option( 'permalink_structure' ) ) : ?>
				<div class="notice notice-warning inline"><p>Tienes los enlaces permanentes en «Simple», así que la dirección del juego lleva un parámetro. En <strong>Ajustes → Enlaces permanentes</strong>, elige «Nombre de la entrada» para que quede bonita.</p></div>
			<?php endif; ?>
			<form method="post" action="options.php">
				<?php settings_fields( 'landrace_hunters_group' ); ?>
				<table class="form-table" role="presentation">
					<tr>
						<th scope="row"><label for="lh-slug">Dirección</label></th>
						<td><?php echo esc_html( trailingslashit( home_url() ) ); ?><input id="lh-slug" type="text" class="regular-text"
								name="<?php echo esc_attr( self::OPTION ); ?>[slug]"
								value="<?php echo esc_attr( self::opt( 'slug' ) ); ?>">/
							<p class="description">Al cambiarla se reescriben las reglas solas.</p></td>
					</tr>
					<tr>
						<th scope="row"><label for="lh-title">Título</label></th>
						<td><input id="lh-title" type="text" class="regular-text"
								name="<?php echo esc_attr( self::OPTION ); ?>[title]"
								value="<?php echo esc_attr( self::opt( 'title' ) ); ?>"></td>
					</tr>
					<tr>
						<th scope="row">Pantalla completa</th>
						<td><label><input type="checkbox" name="<?php echo esc_attr( self::OPTION ); ?>[fs]" value="1" <?php checked( (int) self::opt( 'fs' ), 1 ); ?>>
							Al tocar la pantalla, el juego ocupa toda la pantalla y se pone en horizontal; en el móvil, ofrece instalarlo como app</label>
							<p class="description">En Android quita la barra del navegador y sale un botón «Instalar». En iPhone la web no puede quitar la barra: sale un aviso que explica Compartir → «Añadir a pantalla de inicio», y abierto desde ese icono va sin barras.</p></td>
					</tr>
				</table>
				<?php submit_button(); ?>
			</form>
		</div>
		<?php
	}
}

register_activation_hook( __FILE__, array( 'Landrace_Hunters', 'activate' ) );
register_deactivation_hook( __FILE__, array( 'Landrace_Hunters', 'deactivate' ) );
register_uninstall_hook( __FILE__, array( 'Landrace_Hunters', 'uninstall' ) );
Landrace_Hunters::init();
