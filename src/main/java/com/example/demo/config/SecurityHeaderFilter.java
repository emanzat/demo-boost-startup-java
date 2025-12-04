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
        // Autorise le cache uniquement pour les ressources statiques
        if (isStaticResource(path)) {
            // Ressources statiques : cache autorisé
            res.setHeader("Cache-Control", "public, max-age=31536000, immutable");
        } else {
            // Pages dynamiques et API : pas de cache
            res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate, private");
            res.setHeader("Pragma", "no-cache");
            res.setHeader("Expires", "0");
        }

        chain.doFilter(request, response);
    }

    /**
     * Détermine si le chemin correspond à une ressource statique
     */
    private boolean isStaticResource(String path) {
        return path.matches(".+\\.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$")
            || path.equals("/")
            || path.equals("/robots.txt")
            || path.equals("/sitemap.xml");
    }
}