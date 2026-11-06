// Exact IEEE-754 summation for PDF.js on QtWebEngine without Math.sumPrecise.
// Accumulate doubles as integer multiples of 2^-1074, then round once to
// nearest, ties to even. BigInt avoids precision loss and interim overflow.
// https://tc39.es/ecma262/#sec-math.sumprecise
;(function() {
    if (typeof Math.sumPrecise !== "undefined") return;
    Object.defineProperty(Math, "sumPrecise", {
        configurable: true,
        writable: true,
        value: function sumPrecise(items) {
            const view = new DataView(new ArrayBuffer(8));
            let total = 0n;
            let negativeZero = true;
            let positiveInfinity = false;
            let negativeInfinity = false;
            let nan = false;
            let count = 0;
            for (const value of items) {
                if (++count > Number.MAX_SAFE_INTEGER) {
                    throw new RangeError("Too many values to sum");
                }
                if (typeof value !== "number") {
                    throw new TypeError("Expected numeric values");
                }
                if (!Object.is(value, -0)) negativeZero = false;
                if (Number.isNaN(value)) { nan = true; continue; }
                if (value === Infinity) { positiveInfinity = true; continue; }
                if (value === -Infinity) { negativeInfinity = true; continue; }
                view.setFloat64(0, value);
                const bits = view.getBigUint64(0);
                const exponent = Number((bits >> 52n) & 0x7ffn);
                let magnitude = bits & 0xfffffffffffffn;
                if (exponent !== 0) {
                    magnitude = (magnitude | (1n << 52n)) << BigInt(exponent - 1);
                }
                total += bits >> 63n ? -magnitude : magnitude;
            }
            if (nan || (positiveInfinity && negativeInfinity)) return NaN;
            if (positiveInfinity) return Infinity;
            if (negativeInfinity) return -Infinity;
            if (total === 0n) return negativeZero ? -0 : 0;
            const sign = total < 0n ? -1 : 1;
            const magnitude = total < 0n ? -total : total;
            const shift = Math.max(0, magnitude.toString(2).length - 53);
            const shiftBits = BigInt(shift);
            let significand = magnitude >> shiftBits;
            if (shift > 0) {
                const remainder = magnitude - (significand << shiftBits);
                const halfway = 1n << (shiftBits - 1n);
                if (remainder > halfway || (remainder === halfway && (significand & 1n))) {
                    significand++;
                }
            }
            return sign * Number(significand) * 2 ** (shift - 1074);
        }
    });
})();
