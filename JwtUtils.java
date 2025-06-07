// src/main/java/com/church/cms/security/jwt/JwtUtils.java
package com.church.cms.security.jwt;

import com.church.cms.service.UserDetailsImpl;
import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;

@Component
public class JwtUtils {
    private static final Logger logger = LoggerFactory.getLogger(JwtUtils.class);

    @Value("${jwt.refresh.expiration}")
    private int jwtRefreshExpirationMs;

     @Value("${churchcms.app.jwtSecret}") // Ambil nilai dari application.properties
    private String jwtSecret;

    @Value("${churchcms.app.jwtExpirationMs}") // Ambil nilai dari application.properties
    private int jwtExpirationMs; // Field untuk menyimpan durasi kedaluwarsa

    // Metode yang tidak ditemukan, harus ditambahkan
    public int getJwtExpirationMs() {
        return jwtExpirationMs;
    }
    private Key key() {
        return Keys.hmacShaKeyFor(Decoders.BASE64.decode(jwtSecret));
    }

    public String generateJwtToken(UserDetailsImpl userPrincipal) {
        return generateTokenFromUsername(userPrincipal.getUsername(), userPrincipal.getId(), userPrincipal.getOrganizationId(), jwtExpirationMs);
    }

    public String generateTokenFromUsername(String username, Long userId, Long organizationId, int expirationMs) {
        return Jwts.builder()
                .setSubject(username)
                .claim("userId", userId)
                .claim("organizationId", organizationId)
                .setIssuedAt(new Date())
                .setExpiration(new Date((new Date()).getTime() + expirationMs))
                .signWith(key(), SignatureAlgorithm.HS256)
                .compact();
    }

    public String generateRefreshToken(UserDetailsImpl userPrincipal) {
        return generateTokenFromUsername(userPrincipal.getUsername(), userPrincipal.getId(), userPrincipal.getOrganizationId(), jwtRefreshExpirationMs);
    }

    public String getUserNameFromJwtToken(String token) {
        return Jwts.parserBuilder().setSigningKey(key()).build()
                .parseClaimsJws(token).getBody().getSubject();
    }

    public Long getUserIdFromJwtToken(String token) {
        Claims claims = Jwts.parserBuilder().setSigningKey(key()).build()
                .parseClaimsJws(token).getBody();
        return claims.get("userId", Long.class);
    }

    public Long getOrganizationIdFromJwtToken(String token) {
        Claims claims = Jwts.parserBuilder().setSigningKey(key()).build()
                .parseClaimsJws(token).getBody();
        return claims.get("organizationId", Long.class);
    }

    public boolean validateJwtToken(String authToken) {
        try {
            Jwts.parserBuilder().setSigningKey(key()).build().parse(authToken);
            return true;
        } catch (MalformedJwtException e) {
            logger.error("Invalid JWT token: {}", e.getMessage());
        } catch (ExpiredJwtException e) {
            logger.error("JWT token is expired: {}", e.getMessage());
        } catch (UnsupportedJwtException e) {
            logger.error("JWT token is unsupported: {}", e.getMessage());
        } catch (IllegalArgumentException e) {
            logger.error("JWT claims string is empty: {}", e.getMessage());
        }
        return false;
    }
}