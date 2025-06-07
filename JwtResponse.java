// src/main/java/com/church/cms/payload/response/JwtResponse.java
package com.church.cms.payload.response;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class JwtResponse {
    private String accessToken;
    private String refreshToken;
    private String type = "Bearer";
    private Long id;
    private String email;
    private Long organizationId;
    private String firstName;
    private String lastName;
    private String roleName; // Main role for display

    public JwtResponse(String accessToken, String refreshToken, Long id, String email, Long organizationId, String firstName, String lastName, String roleName) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.id = id;
        this.email = email;
        this.organizationId = organizationId;
        this.firstName = firstName;
        this.lastName = lastName;
        this.roleName = roleName;
    }
}