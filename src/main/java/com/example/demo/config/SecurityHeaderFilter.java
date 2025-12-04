package com.example.demo.config;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import java.io.IOException;

@Component
public class SecurityHeaderFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String path = req.getRequestURI();

        // Empêche le MIME sniffing
        res.setHeader("X-Content-Type-Options", "nosniff");

        // Correction Spectre - ZAP Alert 90004
        res.setHeader("Cross-Origin-Resource-Policy", "same-origin");
        res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
        res.setHeader("Cross-Origin-Opener-Policy", "same-origin");

        // Empêche les iframes (protection clickjacking)
        res.setHeader("X-Frame-Options", "DENY");

        // Headers de cache - ZAP Alert 10049
        // Stratégie différenciée selon le type de contenu
        if (isStaticAsset(path)) {
            // Assets statiques (CSS, JS, images) : cache long (1 an)
            res.setHeader("Cache-Control", "public, max-age=31536000, immutable");
        } else {
            // Toutes les autres pages (y compris /, robots.txt, sitemap.xml) : pas de cache
            // Ceci empêche les fuites d'informations sensibles via les caches partagés
            res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate, private");
            res.setHeader("Pragma", "no-cache");
            res.setHeader("Expires", "0");
        }

        chain.doFilter(request, response);
    }

    /**
     * Détermine si le chemin correspond à un asset statique (CSS, JS, images)
     * Ces ressources sont immuables et peuvent être cachées longtemps
     */
    private boolean isStaticAsset(String path) {
        return path.matches(".+\\.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$");
    }
}