#version 450

layout (location = 0) out vec4 outColor;
layout (set = 3, binding = 0) uniform stage {float prog; };

void main() {
    double x0 = ((gl_FragCoord.x / 1024) * 2.47) - 2.00;
    double y0 = ((gl_FragCoord.y / 768) * 2.24) - 1.12;
    double xf = 0;
    double yf = 0;
    double iteration = 0;
    while(xf*xf + yf*yf < 4 && iteration < 255) {
        double xtemp = xf*xf - yf*yf + x0;
        yf = 2*xf*yf + y0;
        xf = xtemp;
        iteration += 1;
    }
    outColor = vec4(0.0, prog, iteration/255.0, 1.0);
    //outColor = vec4(1.0, 0.0, 1.0, 1.0);
}
