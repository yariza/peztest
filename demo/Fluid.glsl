
-- Vertex.GL3

in vec4 Position;

void main()
{
    gl_Position = Position;
}

-- Vertex.GL2

attribute vec4 Position;

void main()
{
    gl_Position = Position;
}

-- Fill.GL3

out vec3 FragColor;

void main()
{
    FragColor = vec3(1, 0, 0);
}

-- Fill.GL2

void main()
{
    gl_FragColor = vec4(1, 0, 0, 0);
}

-- Advect.GL3

out vec4 FragColor;

uniform sampler2D VelocityTexture;
uniform sampler2D SourceTexture;
uniform sampler2D Obstacles;

uniform vec2 InverseSize;
uniform float TimeStep;
uniform float Dissipation;

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    float solid = texture(Obstacles, InverseSize * fragCoord).x;
    if (solid > 0) {
        FragColor = vec4(0);
        return;
    }

    vec2 u = texture(VelocityTexture, InverseSize * fragCoord).xy;
    vec2 coord = InverseSize * (fragCoord - TimeStep * u);
    FragColor = Dissipation * texture(SourceTexture, coord);
}

-- Advect.GL2

uniform sampler2D VelocityTexture;
uniform sampler2D SourceTexture;
uniform sampler2D Obstacles;

uniform vec2 InverseSize;
uniform float TimeStep;
uniform float Dissipation;

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    float solid = texture2D(Obstacles, InverseSize * fragCoord).x;
    if (solid > 0.) {
        gl_FragColor = vec4(0);
        return;
    }

    vec2 u = texture2D(VelocityTexture, InverseSize * fragCoord).xy;
    vec2 coord = InverseSize * (fragCoord - TimeStep * u);
    gl_FragColor = Dissipation * texture2D(SourceTexture, coord);
}

-- Jacobi.GL3

out vec4 FragColor;

uniform sampler2D Pressure;
uniform sampler2D Divergence;
uniform sampler2D Obstacles;

uniform float Alpha;
uniform float InverseBeta;

void main()
{
    ivec2 T = ivec2(gl_FragCoord.xy);

    // Find neighboring pressure:
    vec4 pN = texelFetchOffset(Pressure, T, 0, ivec2(0, 1));
    vec4 pS = texelFetchOffset(Pressure, T, 0, ivec2(0, -1));
    vec4 pE = texelFetchOffset(Pressure, T, 0, ivec2(1, 0));
    vec4 pW = texelFetchOffset(Pressure, T, 0, ivec2(-1, 0));
    vec4 pC = texelFetch(Pressure, T, 0);

    // Find neighboring obstacles:
    vec3 oN = texelFetchOffset(Obstacles, T, 0, ivec2(0, 1)).xyz;
    vec3 oS = texelFetchOffset(Obstacles, T, 0, ivec2(0, -1)).xyz;
    vec3 oE = texelFetchOffset(Obstacles, T, 0, ivec2(1, 0)).xyz;
    vec3 oW = texelFetchOffset(Obstacles, T, 0, ivec2(-1, 0)).xyz;

    // Use center pressure for solid cells:
    if (oN.x > 0) pN = pC;
    if (oS.x > 0) pS = pC;
    if (oE.x > 0) pE = pC;
    if (oW.x > 0) pW = pC;

    vec4 bC = texelFetch(Divergence, T, 0);
    FragColor = (pW + pE + pS + pN + Alpha * bC) * InverseBeta;
}

-- Jacobi.GL2

uniform vec2 InverseSize;
uniform sampler2D Pressure;
uniform sampler2D Divergence;
uniform sampler2D Obstacles;

uniform float Alpha;
uniform float InverseBeta;

void main()
{
    // ivec2 T = ivec2(gl_FragCoord.xy);
    vec2 fragCoord = gl_FragCoord.xy;

    // Find neighboring pressure:
    // vec4 pN = texelFetchOffset(Pressure, T, 0, ivec2(0, 1));
    // vec4 pS = texelFetchOffset(Pressure, T, 0, ivec2(0, -1));
    // vec4 pE = texelFetchOffset(Pressure, T, 0, ivec2(1, 0));
    // vec4 pW = texelFetchOffset(Pressure, T, 0, ivec2(-1, 0));
    // vec4 pC = texelFetch(Pressure, T, 0);

    vec4 pN = texture2D(Pressure, (fragCoord + vec2( 0.0, 1.0))*InverseSize);
    vec4 pS = texture2D(Pressure, (fragCoord + vec2( 0.0,-1.0))*InverseSize);
    vec4 pE = texture2D(Pressure, (fragCoord + vec2( 1.0, 0.0))*InverseSize);
    vec4 pW = texture2D(Pressure, (fragCoord + vec2(-1.0, 0.0))*InverseSize);
    vec4 pC = texture2D(Pressure, fragCoord*InverseSize);

    // Find neighboring obstacles:
    // vec3 oN = texelFetchOffset(Obstacles, T, 0, ivec2(0, 1)).xyz;
    // vec3 oS = texelFetchOffset(Obstacles, T, 0, ivec2(0, -1)).xyz;
    // vec3 oE = texelFetchOffset(Obstacles, T, 0, ivec2(1, 0)).xyz;
    // vec3 oW = texelFetchOffset(Obstacles, T, 0, ivec2(-1, 0)).xyz;

    vec3 oN = texture2D(Obstacles, (fragCoord + vec2( 0.0, 1.0))*InverseSize).xyz;
    vec3 oS = texture2D(Obstacles, (fragCoord + vec2( 0.0,-1.0))*InverseSize).xyz;
    vec3 oE = texture2D(Obstacles, (fragCoord + vec2( 1.0, 0.0))*InverseSize).xyz;
    vec3 oW = texture2D(Obstacles, (fragCoord + vec2(-1.0, 0.0))*InverseSize).xyz;

    // Use center pressure for solid cells:
    if (oN.x > 0.0) pN = pC;
    if (oS.x > 0.0) pS = pC;
    if (oE.x > 0.0) pE = pC;
    if (oW.x > 0.0) pW = pC;

    // vec4 bC = texelFetch(Divergence, T, 0);
    vec4 bC = texture2D(Divergence, fragCoord*InverseSize);
    gl_FragColor = (pW + pE + pS + pN + Alpha * bC) * InverseBeta;
}

-- SubtractGradient.GL3

out vec2 FragColor;

uniform sampler2D Velocity;
uniform sampler2D Pressure;
uniform sampler2D Obstacles;
uniform float GradientScale;

void main()
{
    ivec2 T = ivec2(gl_FragCoord.xy);

    vec3 oC = texelFetch(Obstacles, T, 0).xyz;
    if (oC.x > 0) {
        FragColor = oC.yz;
        return;
    }

    // Find neighboring pressure:
    float pN = texelFetchOffset(Pressure, T, 0, ivec2(0, 1)).r;
    float pS = texelFetchOffset(Pressure, T, 0, ivec2(0, -1)).r;
    float pE = texelFetchOffset(Pressure, T, 0, ivec2(1, 0)).r;
    float pW = texelFetchOffset(Pressure, T, 0, ivec2(-1, 0)).r;
    float pC = texelFetch(Pressure, T, 0).r;

    // Find neighboring obstacles:
    vec3 oN = texelFetchOffset(Obstacles, T, 0, ivec2(0, 1)).xyz;
    vec3 oS = texelFetchOffset(Obstacles, T, 0, ivec2(0, -1)).xyz;
    vec3 oE = texelFetchOffset(Obstacles, T, 0, ivec2(1, 0)).xyz;
    vec3 oW = texelFetchOffset(Obstacles, T, 0, ivec2(-1, 0)).xyz;

    // Use center pressure for solid cells:
    vec2 obstV = vec2(0);
    vec2 vMask = vec2(1);

    if (oN.x > 0) { pN = pC; obstV.y = oN.z; vMask.y = 0; }
    if (oS.x > 0) { pS = pC; obstV.y = oS.z; vMask.y = 0; }
    if (oE.x > 0) { pE = pC; obstV.x = oE.y; vMask.x = 0; }
    if (oW.x > 0) { pW = pC; obstV.x = oW.y; vMask.x = 0; }

    // Enforce the free-slip boundary condition:
    vec2 oldV = texelFetch(Velocity, T, 0).xy;
    vec2 grad = vec2(pE - pW, pN - pS) * GradientScale;
    vec2 newV = oldV - grad;
    FragColor = (vMask * newV) + obstV;  
}

-- SubtractGradient.GL2

uniform vec2 InverseSize;
uniform sampler2D Velocity;
uniform sampler2D Pressure;
uniform sampler2D Obstacles;
uniform float GradientScale;

void main()
{
    // ivec2 T = ivec2(gl_FragCoord.xy);
    vec2 fragCoord = gl_FragCoord.xy;

    // vec3 oC = texelFetch(Obstacles, T, 0).xyz;
    vec3 oC = texture2D(Obstacles, fragCoord*InverseSize).xyz;
    if (oC.x > 0.0) {
        // gl_FragColor = oC.yz;
        gl_FragColor = vec4(oC.y, oC.z, 0.0, 0.0);
        return;
    }

    // Find neighboring pressure:
    // float pN = texelFetchOffset(Pressure, T, 0, ivec2(0, 1)).r;
    // float pS = texelFetchOffset(Pressure, T, 0, ivec2(0, -1)).r;
    // float pE = texelFetchOffset(Pressure, T, 0, ivec2(1, 0)).r;
    // float pW = texelFetchOffset(Pressure, T, 0, ivec2(-1, 0)).r;
    // float pC = texelFetch(Pressure, T, 0).r;

    float pN = texture2D(Pressure, (fragCoord+vec2( 0.0, 1.0))*InverseSize).r;
    float pS = texture2D(Pressure, (fragCoord+vec2( 0.0,-1.0))*InverseSize).r;
    float pE = texture2D(Pressure, (fragCoord+vec2( 1.0, 0.0))*InverseSize).r;
    float pW = texture2D(Pressure, (fragCoord+vec2(-1.0, 0.0))*InverseSize).r;
    float pC = texture2D(Pressure, fragCoord*InverseSize).r;

    // Find neighboring obstacles:
    // vec3 oN = texelFetchOffset(Obstacles, T, 0, ivec2(0, 1)).xyz;
    // vec3 oS = texelFetchOffset(Obstacles, T, 0, ivec2(0, -1)).xyz;
    // vec3 oE = texelFetchOffset(Obstacles, T, 0, ivec2(1, 0)).xyz;
    // vec3 oW = texelFetchOffset(Obstacles, T, 0, ivec2(-1, 0)).xyz;
    vec3 oN = texture2D(Obstacles, (fragCoord+vec2( 0.0, 1.0))*InverseSize).xyz;
    vec3 oS = texture2D(Obstacles, (fragCoord+vec2( 0.0,-1.0))*InverseSize).xyz;
    vec3 oE = texture2D(Obstacles, (fragCoord+vec2( 1.0, 0.0))*InverseSize).xyz;
    vec3 oW = texture2D(Obstacles, (fragCoord+vec2(-1.0, 0.0))*InverseSize).xyz;

    // Use center pressure for solid cells:
    vec2 obstV = vec2(0.0);
    vec2 vMask = vec2(1.0);

    if (oN.x > 0.0) { pN = pC; obstV.y = oN.z; vMask.y = 0.0; }
    if (oS.x > 0.0) { pS = pC; obstV.y = oS.z; vMask.y = 0.0; }
    if (oE.x > 0.0) { pE = pC; obstV.x = oE.y; vMask.x = 0.0; }
    if (oW.x > 0.0) { pW = pC; obstV.x = oW.y; vMask.x = 0.0; }

    // Enforce the free-slip boundary condition:
    // vec2 oldV = texelFetch(Velocity, T, 0).xy;
    vec2 oldV = texture2D(Velocity, fragCoord*InverseSize).xy;
    vec2 grad = vec2(pE - pW, pN - pS) * GradientScale;
    vec2 newV = oldV - grad;
    gl_FragColor = vec4((vMask * newV) + obstV, 0.0, 0.0);  
}

-- ComputeDivergence.GL3

out float FragColor;

uniform sampler2D Velocity;
uniform sampler2D Obstacles;
uniform float HalfInverseCellSize;

void main()
{
    ivec2 T = ivec2(gl_FragCoord.xy);

    // Find neighboring velocities:
    vec2 vN = texelFetchOffset(Velocity, T, 0, ivec2(0, 1)).xy;
    vec2 vS = texelFetchOffset(Velocity, T, 0, ivec2(0, -1)).xy;
    vec2 vE = texelFetchOffset(Velocity, T, 0, ivec2(1, 0)).xy;
    vec2 vW = texelFetchOffset(Velocity, T, 0, ivec2(-1, 0)).xy;

    // Find neighboring obstacles:
    vec3 oN = texelFetchOffset(Obstacles, T, 0, ivec2(0, 1)).xyz;
    vec3 oS = texelFetchOffset(Obstacles, T, 0, ivec2(0, -1)).xyz;
    vec3 oE = texelFetchOffset(Obstacles, T, 0, ivec2(1, 0)).xyz;
    vec3 oW = texelFetchOffset(Obstacles, T, 0, ivec2(-1, 0)).xyz;

    // Use obstacle velocities for solid cells:
    if (oN.x > 0) vN = oN.yz;
    if (oS.x > 0) vS = oS.yz;
    if (oE.x > 0) vE = oE.yz;
    if (oW.x > 0) vW = oW.yz;

    FragColor = HalfInverseCellSize * (vE.x - vW.x + vN.y - vS.y);
}

-- ComputeDivergence.GL2

uniform vec2 InverseSize;
uniform sampler2D Velocity;
uniform sampler2D Obstacles;
uniform float HalfInverseCellSize;

void main()
{
    // ivec2 T = ivec2(gl_FragCoord.xy);
    vec2 fragCoord = gl_FragCoord.xy;

    // Find neighboring velocities:
    // vec2 vN = texelFetchOffset(Velocity, T, 0, ivec2(0, 1)).xy;
    // vec2 vS = texelFetchOffset(Velocity, T, 0, ivec2(0, -1)).xy;
    // vec2 vE = texelFetchOffset(Velocity, T, 0, ivec2(1, 0)).xy;
    // vec2 vW = texelFetchOffset(Velocity, T, 0, ivec2(-1, 0)).xy;
    vec2 vN = texture2D(Velocity, (fragCoord+vec2( 0.0, 1.0))*InverseSize).xy;
    vec2 vS = texture2D(Velocity, (fragCoord+vec2( 0.0,-1.0))*InverseSize).xy;
    vec2 vE = texture2D(Velocity, (fragCoord+vec2( 1.0, 0.0))*InverseSize).xy;
    vec2 vW = texture2D(Velocity, (fragCoord+vec2(-1.0, 0.0))*InverseSize).xy;

    // Find neighboring obstacles:
    // vec3 oN = texelFetchOffset(Obstacles, T, 0, ivec2(0, 1)).xyz;
    // vec3 oS = texelFetchOffset(Obstacles, T, 0, ivec2(0, -1)).xyz;
    // vec3 oE = texelFetchOffset(Obstacles, T, 0, ivec2(1, 0)).xyz;
    // vec3 oW = texelFetchOffset(Obstacles, T, 0, ivec2(-1, 0)).xyz;
    vec3 oN = texture2D(Obstacles, (fragCoord+vec2( 0.0, 1.0))*InverseSize).xyz;
    vec3 oS = texture2D(Obstacles, (fragCoord+vec2( 0.0,-1.0))*InverseSize).xyz;
    vec3 oE = texture2D(Obstacles, (fragCoord+vec2( 1.0, 0.0))*InverseSize).xyz;
    vec3 oW = texture2D(Obstacles, (fragCoord+vec2(-1.0, 0.0))*InverseSize).xyz;

    // Use obstacle velocities for solid cells:
    if (oN.x > 0.0) vN = oN.yz;
    if (oS.x > 0.0) vS = oS.yz;
    if (oE.x > 0.0) vE = oE.yz;
    if (oW.x > 0.0) vW = oW.yz;

    gl_FragColor = vec4(HalfInverseCellSize * (vE.x - vW.x + vN.y - vS.y), 0.0, 0.0, 0.0);
}

-- Splat.GL3

out vec4 FragColor;

uniform vec2 Point;
uniform float Radius;
uniform vec3 FillColor;

void main()
{
    float d = distance(Point, gl_FragCoord.xy);
    if (d < Radius) {
        float a = (Radius - d) * 0.5;
        a = min(a, 1.0);
        FragColor = vec4(FillColor, a);
    } else {
        FragColor = vec4(0);
    }
}

-- Splat.GL2

uniform vec2 Point;
uniform float Radius;
uniform vec3 FillColor;

void main()
{
    float d = distance(Point, gl_FragCoord.xy);
    if (d < Radius) {
        float a = (Radius - d) * 0.5;
        a = min(a, 1.0);
        gl_FragColor = vec4(FillColor, a);
    } else {
        gl_FragColor = vec4(0);
    }
}

-- Buoyancy.GL3

out vec2 FragColor;
uniform sampler2D Velocity;
uniform sampler2D Temperature;
uniform sampler2D Density;
uniform float AmbientTemperature;
uniform float TimeStep;
uniform float Sigma;
uniform float Kappa;

void main()
{
    ivec2 TC = ivec2(gl_FragCoord.xy);
    float T = texelFetch(Temperature, TC, 0).r;
    vec2 V = texelFetch(Velocity, TC, 0).xy;

    FragColor = V;

    if (T > AmbientTemperature) {
        float D = texelFetch(Density, TC, 0).x;
        FragColor += (TimeStep * (T - AmbientTemperature) * Sigma - D * Kappa ) * vec2(0, 1);
    }
}

-- Buoyancy.GL2

uniform vec2 InverseSize;
uniform sampler2D Velocity;
uniform sampler2D Temperature;
uniform sampler2D Density;
uniform float AmbientTemperature;
uniform float TimeStep;
uniform float Sigma;
uniform float Kappa;

void main()
{
    // ivec2 TC = ivec2(gl_FragCoord.xy);
    vec2 fragCoord = gl_FragCoord.xy;
    // float T = texelFetch(Temperature, TC, 0).r;
    float T = texture2D(Temperature, fragCoord*InverseSize).r;
    // vec2 V = texelFetch(Velocity, TC, 0).xy;
    vec2 V = texture2D(Velocity, fragCoord*InverseSize).xy;

    gl_FragColor = vec4(V, 0.0, 0.0);

    if (T > AmbientTemperature) {
        // float D = texelFetch(Density, TC, 0).x;
        float D = texture2D(Density, fragCoord*InverseSize).x;
        gl_FragColor += vec4((TimeStep * (T - AmbientTemperature) * Sigma - D * Kappa ) * vec2(0.0, 1.0), 0.0, 0.0);
    }
}

-- Visualize.GL3

out vec4 FragColor;
uniform sampler2D Sampler;
uniform vec3 FillColor;
uniform vec2 Scale;

void main()
{
    float L = texture(Sampler, gl_FragCoord.xy * Scale).r;
    FragColor = vec4(FillColor, L);
}

-- Visualize.GL2

uniform sampler2D Sampler;
uniform vec3 FillColor;
uniform vec2 Scale;

void main()
{
    float L = texture2D(Sampler, gl_FragCoord.xy * Scale).r;
    gl_FragColor = vec4(FillColor, L);
}
