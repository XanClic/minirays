#include <math.h>
#include <stdio.h>

#define vec_op(a,b,o) (vec){a.x o b.x,a.y o b.y,a.z o b.z}
#define array_size(x) sizeof(x)/sizeof(*x)

typedef struct {
    float x, y, z;
} vec;

struct {
    vec d;
    float c[3];
} lights[] = {{{4, -6, 1}, {1, 1, 1}}, {{-3, -1, .2}, {1, .3, 0}}};

float sky[3]={0, .3, .6};

int objs[] = {
    0x51,
    0x4a,
    0x44,
    0x0a,
    0x51
};

int obj_width = 7;

int X = 1920;
int Y = 1200;

float dotp(vec a, vec b)
{
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

float clamp(float x)
{
    return x < 0 ? 0 : x > 1 ? 1 : x;
}

vec scale(float x, vec y)
{
    return (vec){x * y.x, x * y.y, x * y.z};
}

vec norm(vec x)
{
    return scale(1 / sqrt(dotp(x, x)), x);
}

float trace(vec start, vec view, int channel, int pass)
{
    if (pass > 9) {
        return 0;
    }

    view = norm(view);
    float t = 99;
    vec hit;

    for (int i = 0; i < array_size(objs); i++) {
        for (int j = 0; j < obj_width; j++) {
            if (!(objs[i] & (1 << j))) {
                continue;
            }

            vec pos = {2 * j - obj_width + 1, array_size(objs) - 2. * i - 1, 12};
            vec dir = vec_op(start, pos, -);
            float b = dotp(dir, view);
            float c = dotp(dir, dir) - 1;
            float s = sqrt(b * b - c);

            if (b * b < c) {
                continue;
            }

            float m = -fabs(s) - b;
            if (m < t && m > .01) {
                t = m;
                hit = pos;

                if (pass < 0) {
                    return 1;
                }
            }
        }
    }

    if (t > 98) {
        t = (-start.y - array_size(objs)) / view.y;
        if (t > 0) {
            return (channel == 2) * fabs(sin(t / 42));
        } else if (pass < 0) {
            return 0;
        } else {
            return sky[channel];
        }
    }

    vec isct = vec_op(start, t * view, +);
    vec n = norm(vec_op(isct, hit, -));
    vec reflect = vec_op(view, scale(2 * dotp(view, n), n), -);

    float col = 0;
    for (int i = 0; i < array_size(lights); i++) {
        vec out = scale(-1, norm(lights[i].d));
        if (!trace(isct, out, 0, -1)) {
            col += lights[i].c[channel] * (clamp(dotp(n, out)) + pow(clamp(dotp(vec_op(out, scale(2 * dotp(out, n), n), -), view)), 42));
        }
    }

    return clamp(col + trace(isct, reflect, channel, channel + 1) / 2);
}

int main(void)
{
    printf("P6 %i %i 255\n", X, Y);

    for (int y = 0; y < Y; y++) {
        for (int x = 0; x < X; x++) {
            for (int i = 0; i < 3; i++) {
                putchar((int)(trace((vec){0,0,0}, (vec){(x - X/2.) / Y, (Y/2. - y) / Y, 1}, i, 0) * 255));
            }
        }
    }

    return 0;
}
