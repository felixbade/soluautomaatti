color hsl(float hue, float saturation, float luma) {
  float r, g, b;
  float p, q;
  if (saturation == 0) {
    r = g = b = luma;
  } else {
    if (luma < 0.5) {
      q = luma * (1 + saturation);
    } else {
      q = (luma + saturation) - (saturation * luma);
    }
    p = 2 * luma - q;
    r = hue2rgb(p, q, hue + 1./3);
    g = hue2rgb(p, q, hue);
    b = hue2rgb(p, q, hue - 1./3);
  }
  float m = luma - (.21*r + .72*g + .07*b);
  return color((int) (maxRGBLightness * (r+m)), (int) (maxRGBLightness * (g+m)), (int) (maxRGBLightness * (b+m)));
}

float hue2rgb(float p, float q, float t) {
  if (t < 0) t += 1;
  if (t > 1) t -= 1;
  if (t < 1./6)
    return p + (q - p) * 6 * t;
  if (t < 1./2)
    return q;
  if (t < 2./3)
    return p + (q - p) * (2./3 - t) * 6;
  return p;
}