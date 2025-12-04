package com.example.demo.config;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import java.io.IOException;

@Component
public class SecurityHeaderFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletResponse res = (HttpServletResponse) response;

        // Empêche le MIME sniffing
        res.setHeader("X-Content-Type-Options", "nosniff");

        // Correction Spectre
        res.setHeader("Cross-Origin-Resource-Policy", "same-origin");

        // (Optionnel) Empêche les iframes (protection clickjacking)
        res.setHeader("X-Frame-Options", "DENY");

        chain.doFilter(request, response);
    }
}