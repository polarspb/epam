<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'maindb' );

/** MySQL database username */
define( 'DB_USER', 'admin' );

/** MySQL database password */
define( 'DB_PASSWORD', 'AdminPass' );

/** MySQL hostname */
define( 'DB_HOST', 'localhost' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
 define('AUTH_KEY',         's-Hp}ze+ImPpS3BKhmS)azy%%%TUaj1@UR ;A9&-mv5[ei$V@3b?Wfp|s8!2{62J');
 define('SECURE_AUTH_KEY',  'l1a=_zf,sz@!tE1|PR;[+ hAg8/dJ+v<rt.pVB{nm <D|MZ#Q7t0vJCqse)3O;C$');
 define('LOGGED_IN_KEY',    'A$}]S=-,*?eA?[,+RhM6L,Ja.(l%+H`2pUxW(R&glpH`uk.~P;ASaB8f@nWd(+8J');
 define('NONCE_KEY',        'S3d+mePZDgzqz|f$[2&0p@$@z,dq8rX4pBw$Z5A]Z--| +B]zL&|Hb-+kxUO8|yH');
 define('AUTH_SALT',        '%IH%/*{RgXmuMGQV|gilY>#V3}k3L|~~N|s(8=UB0CLcm5)CE.N&+n1 vSY+N(6s');
 define('SECURE_AUTH_SALT', 'r=&uad|OqyK3&q&-|szyE5:<y]8ip7/lItn-b8(~Gqp15aD+ .f$RY6= /4L-(^[');
 define('LOGGED_IN_SALT',   'UJ:<yFjh}?|E4/DaxHgJb,D6?~Q(3,H[e=x+|_1]?J7pQE@pO e5B^^:Kr``JkVQ');
 define('NONCE_SALT',       '2s:1=c/dgu%sLovhq>9iToq Jwf<,e{|$+8n@UKbqh{gYT3h1,hn+$oD^; A`(|#');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
define('FS_METHOD', 'direct');
