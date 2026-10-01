using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using UnityEngine;

namespace BilboCity {

/// <summary>
/// El arte traído de PixelLab que no es un personaje: los singulares, el mobiliario de
/// calle, los chasis de vehículo y los suelos. Este archivo NO se edita a mano: lo
/// escribe herramientas/sprites/arte.py, y herramientas/plano/arte.py comprueba que
/// aquí y en el bloque ARTE del prototipo HTML hay exactamente los mismos bytes.
///
/// El formato es el de siempre en esta casa: un índice de paleta por píxel, 0
/// transparente, deflate crudo en base64. No hay PNG en el repositorio.
///
/// Vacío es un estado válido. Lo traído sustituye a lo forjado cuando está; cuando no,
/// se forja, que es como arrancó el juego y como sigue funcionando sin bajar nada.
/// </summary>
public static class Traido {

    /// Clase y no struct a propósito: la pieza guarda sus píxeles descomprimidos la
    /// primera vez que alguien se los pide, y un struct se copia al sacarlo del
    /// diccionario, así que la caché se perdería en cada copia y se descomprimiría una
    /// vez por consulta.
    public sealed class Estampa {
        public readonly int W, H;
        readonly string[] _b64;
        byte[] _px;
        public Estampa(int w, int h, string[] b64) { W = w; H = h; _b64 = b64; }
        /// <summary>Los índices, descomprimidos la primera vez que alguien pregunta.</summary>
        public byte[] Px {
            get {
                if (_px == null) _px = Inflar(string.Concat(_b64));
                return _px;
            }
        }
    }

    static byte[] Inflar(string b64) {
        var bin = Convert.FromBase64String(b64);
        using (var ms = new MemoryStream(bin))
        using (var ds = new DeflateStream(ms, CompressionMode.Decompress))
        using (var salida = new MemoryStream()) {
            ds.CopyTo(salida);
            return salida.ToArray();
        }
    }

/*<<<ARTE*/
/* Lo escribe herramientas/sprites/arte.py. Vacío = todo forjado. */
    public static readonly Dictionary<string, Estampa> Singulares = new Dictionary<string, Estampa> {
        { "abando", new Estampa(224, 96, new[] {
            "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" }) },
        { "alhondiga", new Estampa(128, 128, new[] {
            "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",
            "+xLfjlXqzF/lu/bnbT59jY//Kf4f" }) },
        { "almacenes", new Estampa(160, 96, new[] {
            "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",
            "/wA=" }) },
        { "arriaga", new Estampa(128, 96, new[] {
            "tZpbkuOsDoCLW/UzL+zBniLJAtj/un4kgZAAO54+c6juXBzMhy4Igck5Z5+heE+v+I7/Ca+n9pLojWrJF0+FKlOhDzlztV4r+ezHtSx/4mY8",
            "Xxr3927tClVq7SO19lzwRzUvWpAyZyVTklDRrXZXyrokvjnxt0RdSVKixleNj1aFyGkIJTvn86s8KdTU0L3kD+NKG0xK8Eovvlvd5/J5UgpU",
            "TXu+kF/yJyWw5lOSNkvl8/pePqXqj3RIjWmjT34zvEC7tPDb5hS1K5X/SH7tT376KBk0ToivPLa7YmKn+At+0uNmeFPXB1pIDbHzSXnIP6jc",
            "t3UkEQPSwQ3vCO/e8jP+zW95tHk0/YOOK/+1VoEvWbfMtexc9nx9v5Lu8CKgHNsq8Pl9wZ9i4AX/Rl8Hu0Qmvm/xI14WxVfSK34csajdt4So",
            "xufQCfwS7JfykI9XzHUz3pYt3wXQKmrWsWKdc/zpMb/eBP8O25pefBUzEr/6XqYwR3wf/o385kZ4G4wjvpwVK/9d+S44lt5KNVDPH/rf6FW/",
            "cRTnTeWXzu+BqvPvNfBw/N2J743TfOpW07/QgJNO0MrD+EMk8JvV/sZ2vhnxN+XBv9PAQ75pZRUepQf+S/Gz5DcN7MpDvqOyacDaxn9n5vvB",
            "d9QD/3+S3xPdWFM+W76nHthwKf/nmf1h+K+3x8Z3kj/7H/KD2xYKqOa21Gjb/U+VKjzxreaz/d+C7ycfaN9KflIK+f4IoPTW+U3+bPqCwMvx",
            "jz0NygmF/E/5i/QOXA/4IL2RfIpAk/5hGG4MWLLKNOHONf9EvtYeDOpJ/o/ke/I/K/l+4wOdP0s88avnr8LXuegbX8qvTdAcYMjfqBvxXzla",
            "NXXgsO98C9pHfve/dMlfNODjs4IeJwJQpePwJ77TfI8pNunfSf076Xn/S/EYDsj+tvvfkB+T/jn+IL8qwfN87LQpnM5S5npOXHKDb5HvLviW",
            "x58jvg//QHon+WbVP+efk//jTBD8Mg2HRWR82c5aMJdI/sb+lP+dF3w2wSYbeFSs5gv5D8V/TfYnzTkyQeO3T85p+/Nk6yaHBTzDRfyzkk+d",
            "6PyN/GGW3238b3sN4853+XOTPzaZu//Ri/+9E9LAd47mg5p1W5J+zr8S2T/u5N+5lLwaoLjlV8qg3YX8Vo0/1P8t/5fyK7j0fwsLsPv4K/w/",
            "/Lq4ofxp/OXPkv+8Lvn2d0VEXvb/lgGV/GZ+z3+u+MHu467z21enfGXij/ibpf6Rn1X+w/YPdmPYjbB2Mn2PvoIPCfE2/4T8J8v444b8VmZx",
            "bs4IfSlrnqi0IUyw5bf8I6/+B8MqSHM2weiPlFCCLU5Usd3l+A6/58/5z54f7BLPlaVLDU626OU9L557LcHf5R/YiTH+HMf/4Fa81m2pVWpz",
            "9UY7/Sa/8yg0w//1+tOn3fwbvHW3fJA+oDir9eUnp+W37oI/5T9BZvGbUVBC59tyGwa9tr+d85/E+y9z/u03o71rtUrf+eADMlwvdzmR/8JY",
            "Xeaf3fqDR7oe8o7+wfYsf9XAPFDUMEAT9Px34qfN+hMd8cLphucP+ckHtk7Y9pE6HyOV5s/7D7j+dm4fZG33fM0HDdzw0QQkf+e/zXjE0Ply",
            "DbFMJsIG3fZD/+gDHIl34XksXkoxe/njCAmm3KWb3fZSfogDywiUmw8ihpWZT/5PM32vc7MN5Rd+8wF3ORfLxpX9yQgH4PVyv1xLf8W/uWfa",
            "TChy/OH+Q6FEx/OaC+PLphSstOfXUbktpWdRvKwsEz+60PCiA9uC3At+HQXbwrIFXiUUxY/WY+8CtEqzvav2vLR959tgjFU92N0Te+P4TvEo",
            "Fo6/1d2rNgDd/nHUVv5naQxnPOYb3PXVPZgdFxbbpqPZwGCAMvZfkY8W6HzIW0zbypuk73xj2gOet9E+YDkAu27q0AxAfGh84TOeO2BwK3MI",
            "Ykh64lsYsu/TmEQ6YL4ygTEkP+O58Wd8NZEKPsr+zvAMzeOzs6ED4Ot5uje+5eMWYOWjA7o2SnDOsGZs5eJ2btN+s/vbH0d2mDwd+T38AFxA",
            "bQBXvvOMD8G2EFRa/l1lMDgam/PTnOGQLyN/yzfCgbL/qdTsfuzPj6v3m/z6vEkHNAhE4lJa44LvgB/l8gdHY+cHi2N0+L/IdyzQX+eBj+9+",
            "gP9z5pSGH1AgnvSP+ybMp6tlJGCN38Vvi46Ij5K4AB81//pT5c2D7/DxdL1GVgD+0L6xZW7cSX5f/sSFXz7a/wp53cdXWVPn/1hb5W8PkY/U",
            "ejDJjyjNL2PCqT5wUgcUH2rIkVSn5273fgIE+Kj/XtAPag9KVBEIWYofK8+M+Fu7Dh2QfKihH5wOu3M5NR5GMvrBW90IDhsVP8JTkhH/If89",
            "8QEo8wGfo3ys4fPbm2Paea6inPowDFhheux9fI5N42L+x/z7BIHZ2aCG5r/q1ff7yQOY4zATHxsfj0iwcfn8J4FpT9VIrZGj/1NLXyNkj1+/",
            "FHHup52FwuTqnI/IaD4+/5eajPhCG+p9Z93nvyhiRx4bN/IJCYwfI8/YGDJxk6AGJOqE+V62z6Omi9R4L+eZBB+1lUyzsXy+APrv+buZ8nn+",
            "Pv1KVabvc+NkTbH/W4NXnqrg8P4t3+p6S+NQTuX/ho6dKP6Zy+74wIZvL/lN/qnxlNOZo8z/ahfzpP8zn/+Kf9048z9YR1SpNVIZBynaJmL/",
            "bvon6/SLlbfQKRC3bTzLtULlY51RBfCp0FyshJ6Ee6b/tfGci9z/xlTykzlkID6V740/5GPjvoUnxGs+Hu3LNYVpJUNOQVXMdz7kl1/4c+Os",
            "foqViTqQ+rE9DBHlL/i38uNz+8yBmVXL7peaBtT4KymOxntWOtoNfFoomLAJEXiKAF6CoYMDcvwLfE7NCEUP0RqkY3d1PzycXF/7v77UP3r+",
            "ufI0v6gTkP1jUVVqL000uGPxdQqQteQ3fIuV75VwRR/C5MOWRVTB44HVAlGcJ0ZniR4v8lBJ/XNMJsU0lRgiLjGlcEXB6Z0yypEzJeT72Eh0",
            "PJOcNUam8PxFLBP1dfghNn6Wq/HpAKrcCbnYt7jYynlQu+zaladf83QiVZx9bWbw+hBv9OoIN59v9WU+7wqvJeX5PK06EiuPpyp3FHwykeAr",
            "7Q1+f54qDlhXX5n40zlgeUjWK2/IPFBao4n1vz+KXlKXX7RM/OWEuzhb3eV+8TnyxOljPzCsjvHyf1oOU/ul4ilO/VbGi6Bc5T8=" }) },
        { "ayto", new Estampa(160, 96, new[] {
            "7ZvprqUoEIADsvyTHyQdn0HR8AK8/2tNVbEIisu5y6QnmZrp0+d6BT6L2gCbCyll548QXDzJIJPoIip9ll/dCJenHuVpUH7NNzzKd/n4wFFy",
            "d3yQpyGIryPwKPK1fJXvLKd2l/qjW+kHkRRavpY/3+TjpePS45B+FPmvn+OTX9Tfge87+pPyhk/8Hl/X/oYP7U/8vv3Jk/7g4Xbnz2YhRf5S",
            "8cl2fqPsbZs+UngaitGUkYes03z1J/gUCudaFdFENogj39DwycZwjnyi5SsTK6r5bdWE0elgDqp4Lhdn/Yl7/clb/Yk0NaoKDJofQ0UbNo5S",
            "XeGC39x4L+ziujqNzb7Mp/4NPi6f+VSPT3EtmPgiXx3gz91XXTIwgK/xgWEIVOBX+Ng0De/4tEKPeccXgq+EeaXF4Ft5TQjOwHp87ahwi1Jv",
            "+VRohEFTwdtr7/hQ6Qqc+YKvilkCfwAFMvVGQhNpQH9qaEvG4B/7QICBGMTQ/oJn2bXCIiyMFUJfEY1GAxh1IcAwhXxxUEUxtas/fuw7xE6E",
            "ZPUgPMdAUfPFoWCGDzVi4B0J0el87D4qgeFM5WgbfK/CDccLnobdDTAqNWcltXvGbCMf57WmMaaHrmQ7BT9QQxxEqioP9VsFffAbHig7WisP",
            "fFI18yutcQxkdjOMKeNDYfp5YeNeZiX0ataeBJUin3COAYZzb/hWhyI0PKEvCbMtu+pLZB7RB1Xk+2BNELuCzlazruslX5llaTdnDDdORP37",
            "F4pLU+WT6SrxTnmxkY6ViViNAdW4Werdrbv62zbiS17qRTbRpwiRQkSjwBcNfa7kzMYj3/38hgD6MyYHEWr+MIjMeLv+EqB+5PM+a9uZzbgQ",
            "ktZv+PS2uTI1Xryo6/2BT8iqlrsRNPAyALiImyAFRbu44tNyIfdv+YTUVYmo0kdJPWSDPH4Xkc8zolPNmk6V1thbvFopAAdeZJ8vqVvpFXQX",
            "wlF/Qj7MbubTIk6wjnxSPbar+eziKrOg/HHUHzj5PIc0Z2/mV5P+lOeKVCmjAjPfpWT/q/msG12tvx6fM6vp86luQZdSj098CvkgqGU+Ue6I",
            "9+aJGToGHtzY8g1dPkN8p+aQqXyp9pr8pmIgw7JMEyCPfNTKn6Sx7wPf6uq4+SGf3aumJQndWfGp7CE7n7KzEHMr4RCfP+DbrvncepKt3El8",
            "uXxr+DrNQmxww9fNbyjbes3n4E4M3pDI4dPa2Zh8J+Q4KLGoH3nkg2YWn9ri58L5ah70l1l6+puu9bdYuJMBGGHi51zz1cFj9w/g43T/zJHM",
            "0A9Ff+ql/nY+vtzw4WYFkIEBxs8l8vlcoFaJq/BNjothgE7hfjAeTLVbqFdFFd/q+BOfBgucoS6L5qFaPrhbwhTB8PSpFrA/n/yjlaniwzwC",
            "fGg8xsDgNV+rv4j3wCfnna/RH26VYCmdCmr8XAJPfCx6Jjo16BVrVJH4KI3AZbzfOUUptB9f7F6XXcZn4g6qN7859ezJUE8p/sF8QlVBsmCe",
            "R/Vl/clqFRFNfLqYX3nJ1xrP0NdfHkju1Zsq8ZkHD6lnVmhFq/cHPl0a4NPpB747/73R3znfx/Vl5PPerXEdOiY+WfHpqiyGVn37O+rvjs8/",
            "8tGINd+4BhvYFZ/u8umv8r3SX+SjZyG+BfMzRNAT315VxVb9/PGaj3X5+utfn/n0CJkLXNi0fL67/M05sdIf/4jvPL8Xp295ge01JVrMf/X8",
            "Xkgpz/YBmH/Pdw5PlytElfQ3TfnKNMX4cttMnupnNsmX8Q+y7GH9MdxufMb9RZcF664XK2B55GMv+ZjyZT+jre99+ZD+eDLDfJxf/M/7vHrz",
            "5X785g9taz7WKP2Gb9CYmpKLKPFmkyI6CPLBInut+Z5PnMpXUTZunuYX1n4ibaBSpo1Lj+s9ABrHRj6L+yiJb1+q1VlnvyjLADLtn7JnPh6X",
            "scTnS5KRD/sHXnE/5vIY9Kf83qxNivhV0s85q6QDGFy68Ec+lpdhcvD6/bkg1M5+L+SpGnzTLqbbpD5c97FHvrTJKKTISV3EqZJ3u0M1H8bn",
            "rBZ1vUQXUX0SKy5G5beu+NRF/AsbbYwL5kQpOIY4iC75E7+3wUMl/zC7/mBYWQxU5j0RecCLd9iFSijmHvdfwmZw/xSimci2IXWprPbFek6q",
            "yXSi/qBKhvwGfHkTu9nrjSXtvtz3+9XBLHHQwB/5FkxRTrhhT+i6naXGYXJtB3ywuMECYTZeS7VX2eQLGa/4SKVK4NtI8UuPr92/Jz5unE18",
            "GfByozvPEqcDCe1wKWfLJF7sqgfRxivkg+Wn7fBRuq4KJqw/gG/hqimKgG/uSEhPMVCZIrG4XzBaD0M6oQ5Tt5k4hNMJ+bL+6vr5eP6BZTrN",
            "79BWewJ+0ZGQzqDxxAWXHus64vIDAmI69ghTvnUcR9wAQjnzDZh21mVp9Nc7n4FhENDx8npAPlKJ4AfJ82UDVAU5QLtlBr70m6nTDPiq9w/o",
            "jJ0aynDkE0c+C4srmueTAB9MwWpws2Lj9AzWZG+0UFNtIFOStLlIG8vUgDY3LI9/5nPv1CriVXzixMdWS/fPSyVgMbCoPfIxGJPl6TsYmJjj",
            "ZbRIQqOdG574xrnpHoUGXRx75JvoeGZJUzVGWdc076lCLmLDaKikX3D9MY7WUpnvLe3TGecBMN9btWUBO6WOs02QTA1ffZKynw8uZqRDBpqS",
            "OC1QlOD5ZSdOWD+CRjB0eY8Gbjm0hwKB+LgZvXRbto9qXxP4oH+GNuLiIG7y6yq2Zn6VlKeDlIqPZz5OfD33dcjHD3xRf2gJxNcT4INSkSPf",
            "Eqd9BD4zbLaJ47Kjv6nhQzRsv3qc36RNmA0sQzc7mxn4pEx8m4su4hKfg2aK7G8tE0GTAfPrTMsH+gMjiXxn/VV8kIATH550FdspfICNfFQr",
            "W/BEFzes4K/ilR74NrpKfPkZi3+sKwvHqEN8JvBHvs0TXwop1ba2A+0g38YynyW+6EbIl08Kp9XPjozfkf4YKhsfFj9Qf8gHvW+7YXrig74f",
            "+WB6oO3YuinqT/f8g/k068C36Hm21jq9OOCLadJPurdA7+vPHfh0z3+nwbiAtdLuH/jIHlb301lqPqAiPkiEfh4zX78Z2R+6LTTekv8a8A/e",
            "56v8dxIwv1hrtvHF0+sHMLzl9H8W4MMdF0OFwYy+C3yLI74J+dKLCraRHl+AB9rq8qCrPwWPMVKuRf+ILoKfHk33vMi2OSvjX4Fm1eElitmG",
            "+DrNJPFht/QxwQM6HeDRkKhaSHb4pA+7f7Q7Qb3dgJgMQ9RXoNJ2hJBjRpN6wIzQeZnp1DvoD5LUJOrz6R4fJJCSrlvpvk5l6VcbOGtr7vDj",
            "HA2Pqf7LVgeh5DLJ6qguvvEU33So1+e09zJlk+HVOzy9N21Ixh6fic1vmtVCD8r0w/tN5YUSoT6R8Swmnii8Fo3vWd6/4KD348/rFxC7l6s6",
            "pAjwfdrNzffv8Zn1Uz51Mai8H1U999aT4/InFbUv+ZR+PdLp1vp95u9I3Hc4DSRV911JqfRHpqA+mvY3T/9T+nvPpz7qRn3Y8tsi1W9KXIQm",
            "mxheihDy8cGleC1V5D7/E534CqKuNoRfvRz3zKd0FWRvVRSPNi72CinPDVx99Miv+NL7fU8vARIfKupmuGHgv8D3biqIT8j/Ot/dmVmHr/Xf",
            "45Bxe/EtXzwx+Vm+/U0v2X/P/K/hU38tn777VyH/8/3n+dReQP2a/f2pBNKfOG2IcfgFjvfnj4Sb8z9bhYYYV6hZ5cKKbqSeBrw3nzzD82Nq",
            "5Qx+x9yTpCRPCfkf" }) },
        { "begonia", new Estampa(128, 64, new[] {
            "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",
            "8GdwOwWMAKxYADOr/X8B" }) },
        { "catedral", new Estampa(128, 64, new[] {
            "7ZlbjusgDECFgcy3lXZW4/2v62ID5t2Q6Uy/rlWJNGly/MKY1Hvvv1j8TNCM4t8QfV7DXPP/TjLz67+8JxQkj+Xog3xjhBySihDlMAx799a5",
            "8AY/i6BFdvnyY7/n4OVlYTvvDwSIKtA2HwCm/IrJDn6pHxrv2I3MZ6Fd87+8CT83Uz4M/D69dPwjvgokftYDoB3f4OOajyqQdEmJTvl7OR/g",
            "zruKr/JD+8MzrYqJWU0mHTCBv6cRR77KfT6llLagpdpQeu5qTEtS4UOS+3wKMY4eDXwXRPhOBLEdKY99/AHihfv8kEsm0MV2KPbP+fj7/FjN",
            "HJse+Gy+2+K38U945pN5VdBm8U/ZdM/+NX8qhl7Yr2CY8+3C/1P+Me2ClvYH1ayCeeDH3I9/4XtVgBRfauvIB00952lXTAxY5tde96oAFfyS",
            "H/EuKkCHa+OwlI5fSAcfHglPip/ytZImJh0Hz4BcCCQW8ZrLB3KGv8UETPzK0cKPCmS+1KwpP808vZf5W+bngEU+eVU18VkBOqxciSVzYX8o",
            "uhBTyXPiRgVgq52GzC/We5f5QYEQTL6UK3bN1/4j5n4oXoI/wkf5yf9O/V/FIh5C6n/q8Cifn1ctGDWfQ17z+VFA1gb3iwKwu6EA5tfWu8Kn",
            "NR9avpNUDrdZVsHXfLHaNUynKch5eoRWUs/LY5QvVsnKMPBxsD/PVZ6McMTpc2wIoDjN6w3XfJzwxX4Xl4CqC7oW05+o+fYu31vugVB7iUvB",
            "o//xBh9X/g/GhBQIl7fxnH+44JdetuWLi3u+tHqx9WP/7OLj/Jvxq5M08nP9j2sfyqpGit/kY67/NPJbnVZ8br1CuG1aU5W/p8ALPnW/XPEN",
            "h9xFw52lW3xJ2FT/Oz4Nqi74snXMPT9xDUTY5Mc1J69/DZ8mvgLtf+r4iw5YAk8WYU8B6vr/in/R/3X8rEAyZL//afuv6xtW/JCFkPGlWlzv",
            "f1yJf2U/0nMqVf9tBj5mvPqddvZfK/5jkMDX/QeYof9H6vBv8nvfP2s+V+zefsT7fDfNv8j//vb+W6Xl+7r+JzwlDW7yXcXHhl87f+BX/U/e",
            "mnEhqGfdlv+v+Od5zvjScTd7wzgL66UM7+7/J/zz+RQFrvilDtT86/1Ps/9LgoV/8rRjBTb5X9T0Mfq86TjsP7FKduGfcd7v88uzy+vU5Tip",
            "fzmZCl+CcIvfH7/mW2+v+ed+/Gnkr94/SvztaH+4lPlnngLb8afd97+J7wz3D9i+fyz5dwp+n3/n/T8KucoXVbjMv6DWeSf/b/DbSZIyt+cH",
            "Bbbqz4/4k5JQ8V1df93AN2/7v0+Pnl8WH+cG+8H84X9gl+vvB/iz/ueD/FEej8/xH1P5HH8hU/47f+T+UGr+e/8k/wbf3JLfUCkw/wE=" }) },
        { "merca", new Estampa(208, 64, new[] {
            "3Vpr0tsqDJ0B2d9vTTLZBZAFaP/rKhJvEE5627mTlHZaGR8rHCQkge09eP6LT/ccm49/PrKtA/NPAgAHt/s9/u+9c/DlfDDScTdAejwezOig",
            "r+fDjSDycWwfevq5fTCfZajE5uHG9nHCR3vwQ/msje3jTOYDPvLxSvtQPkqT9cPOFpuH6HHMh54Qnl/WgntS4gOFD5tH7INfzSeumszHQbLP",
            "N/NxTCjxcdHfvKHYvpQPxtatH+d8zKyP+0PlE9TA4oMmhleADfblY/vgxnzAODYPQPW3SO3+uCl8vAXEIjrMUd2bKromMuAS683RxN/Qq2J7",
            "PkzGdeuH43UUVj42NjrQV5FE5Eycxa53xmLGNgBogNg9AHTs/Gsdn+RrrvO3OD58PMzCx8PPT6whWK23UcQmErDaYCugE/0o2oyFuVfBKnpB",
            "0zvYxyUDVX9jenS7GdT5kOhiEZsYF2HtxTpcxJfYMkb7Ui9dYCd/c2kBFX/jRmRVPpbOMjcGj6K2zC4MvYYW0Y7Y1BtGwEbvokyoJezCR3YJ",
            "2d88CEO38jE/R/kFFrGJqdfZBrA99uwfW7Fd7wXWanoRFD7JQNXfZEfHwWnmY884Y8kDRKQiQt+LSi+8jT1+S2/GzvEAJKiVfOq54rFujQe2",
            "Gjg5ztmW5dGiRAOo4hvYUwFc6p35+C6+gcQHFzONwudsuoqtWWyhru9VxQPQqoBDEd/VO/DxkCh08Y3to/KpMUvmhrJzF3dyI6D6RcV2vTN2",
            "0RuXB+ulFWs7vbq/edfyacpF0ZEXfwsQfTc7QxTLPEpvjjhVTIBTFefHUuBtAKrKNGxVFhp24iP2gVofyHKyaz4NnXPDIFY+k583LM3Y/rE/",
            "wCZxiG82ZZzB32TPoPAZfLdG0BM6sV8etsVrDaBgX+kNk94kjvWBGGSMBxziLuO1OcbQrQfphsXfwOp6Vw1N7+BvRuzR8UkBzqEer8+yWK0e",
            "eGnxNzPG6w32eKEXdb1uzadiEFfXD2RGqK0faMnBXmWEMCYSe5VI9th39U58XCpIS32dym1l/ciyNG0tmlYsmlZRzeKMbYBV/I96l/0Cr/9i",
            "Hy9ni8zHLfH6bG585jwRoliL37PVzAzADCg5RTSo2GF5VL32Sq9g1/VDuXrr62s+QuAz+f36abZ2FzXMWQAddud6C9a8j53rUej3p3n9wMIn",
            "7GsyhOZO0Py8w8KfYO0L7LpfcHU/J9aK3oeo+xutfsHRlq79jbBhaXKy3t9go1fBBtjU1052p+08UTrscRmv9zUzaYXyLma597FXelU+bqgP",
            "NvVo5wyDX1jl0GDA2km8wqqPXWGn+OaHesendARK/hn9rcSstrlviT5IiSLe0sWh0ArlFdsqAU1vK6oV7FTvpHq0xjfvZf9D+n5Bi1nsZGG3",
            "XZvj20ssabHQbvSeev5xtb52wgfU/ba2w3JjL1zt8gQbHSe8sSMs2Hd2j8t+wbnuvCrFa6+c7wx5TzkTgF7sYxasheWEpTlHXujtepV6tBSg",
            "bb/g5XKzP1XPD67y3oJ1LRY6NUeqenvsHCFX+6z19Sa+LWHGdREHdnHI9GviVVDTsaSLa7xOCbTfn3pZThofg3UbH8VyJoBYT0JRBRgkBTso",
            "I7zEdnqHn9DPD1JJ3d7Pcfmm8ElvwY1fRav2/gWsfQu7nh8M9Y6YZz2/fgYfpE1iUMWXgD/HNlGJb119wPvt6ABf+n4ul9MSD6jaB3++9X0j",
            "GNfsQ2nzza9PY3398R8fLJ8g5PenEuGEz0NiAX3JxyGbwVGtD+4o70vm73c+nc/6/U6K1/cbyvLBkcCH83HzaKnW1zey6V3Wt/NJ9c7tRvCv",
            "8HGZj8S3L+dT3jcaemzs89Ft62+Uz+PpH1k/97TfXu1Df3U+w981D618yvvt5G9rvMb0IL//a18B8nlHUzrcmy45aW9HQ3s143O7e+to23kI",
            "PdJZ/JyhRIOJDcvkou2viK+oTvwIlatyE6UioQHZrqyxk1LskNZq93DNp+xlj5SAIh2/1DvyldzPGdtP/m08pZUpGu7pN/OVSS1D6VyV/qhK",
            "J53dc7iMtu5/bneK21OfVITWsMxInS80ylXlY/ZQLnWjfaAzz7XSiysrVzQMNQRf88/9btg++SHDX2RZwfIIMLXyf2lEaYTpXpMzlAZovDRp",
            "KIMamrWyog2g/738I7Kza6P16Uwx8kFxt5h/inlyKApoP7hRNgsHTpFa/rk9rONP6tpMZPewMDZ7wKue/wvCpqZurOzMcvbQ/p2Hj/DJfGAd",
            "bcYc39m24/4F" }) },
        { "obraGuggen", new Estampa(176, 128, new[] {
            "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" }) },
        { "sanmames", new Estampa(176, 144, new[] {
            "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" }) }
    };

    public static readonly Dictionary<string, Estampa> Muebles = new Dictionary<string, Estampa> {
        { "andamio", new Estampa(34, 30, new[] {
            "vZPRDsMgCEWhUB8k8b2/gP//fwNtsw7duibLmhhS7ylcbyzA3SelK4L4AijE5SNQpZRap9K6ul5d35loiAhUD70x0RDRocleB+KkSV+ReJ1R",
            "ikgkEMUY1ZREvCLS4BTR+1geTfedSEBjiDWbDiNhU01BJ7xMiby06eydVCdTzL81yb2HnWUgega9h+n1fR7EtVWd5dEyNeIXeeg0D+7vy0Kc",
            "8fnNmdh9+VlgTlC8yZH4/q7/idi22z8yPAA=" }) },
        { "antenaTv", new Estampa(14, 26, new[] {
            "rZDBDoAwCEPn2hqOnPmH/f/vKW5Rl7ibnHgptIRSfiyuadcLYBMx3pMRy71ikza5yJ48NO0kkX0D3VnJWnPKs5gi0gCdkE5mBjggDQo723jI",
            "tHWNOjlFcWRfdB9A8es9Bw==" }) },
        { "arbol", new Estampa(28, 30, new[] {
            "7ZFRCsAwCEN7h0S9/01npSsj9mO/g+VLfMQ0dIxfH5KVzsRLhoa4kBsVwrfQGOjbSGHkw6m+/RYNBEGzmB08R0icGapfjo1F5LoI0X11MU8C",
            "GpiKmUacCtZa0xa89epjLg==" }) },
        { "arbolPodado", new Estampa(20, 26, new[] {
            "tZBBDkMhCERds5UbwJgYdg33P1tBbb/WdScGk+fIKKX8R3AHH0Q8Bd+ICDyNwMFCwfx7vVYRTZfqx8iSiqviqo8rG/po6bNZDbHMjChpk6Qv",
            "Vo21HlSnMU9UM0myXYho7D2olMlKIRq197pysxIZzM4ZmG0fWwpbv1m75kftgkRoewKHrFksPFPl+BXQDT/RuJ9y6A0=" }) },
        { "banco", new Estampa(24, 12, new[] {
            "hY1BDsAgCAQ3xhMkHnwGa/z/80q1pNo0ccKFARYASIltQHol4sHoyD0wVTUN32Wjh/dj4UL4WvGyNCN//mWh5fClLfhCePlwys+bzzjt/3EB" }) },
        { "bidon", new Estampa(12, 14, new[] {
            "XY7BCcBACARls2oTEq4NH/bfVqIcXMjgY5BBFHEDYObyQlVXVbYHqwjE+Lqjab/WytweXiR3k6eJPM3uMfvAzL/hNJxG0DfnhQ8P" }) },
        { "bolardo", new Estampa(8, 14, new[] {
            "fYtBCgAwDMKEYPv/H4+1nuslKFECTdr+gPIs3i5HqDpJfJr5w1JB8gA=" }) },
        { "cabina", new Estampa(16, 22, new[] {
            "tZDBDcAgDAMjeQ8rO/SZ/feqXQiIB89aPDjixCgRgakYApNkJtEs0FNNB0qOKugMtqG4JrjfDWCz6i4365bwlINzcX28/TQ/OOY5tFlZafyL",
            "R97e0P5arJXFTS8=" }) },
        { "chimenea", new Estampa(12, 18, new[] {
            "lc6xDcBACEPRa0H5Yg6z/4CxOFGlCtUDI8Q5/wsyV1SXNCyF9FSOw1UZDgKeiuHxkAxdI8zrbpzpmtbuNGh3aMyxD7Gc7vPjCw==" }) },
        { "climatizador", new Estampa(18, 16, new[] {
            "dc7rDQQhCARgw0MTCdKILdh/WzeQ3b3NJTf/5gsorWXOoN7eGQch+YKyALrcpEqA0YmY7wGRM7SDhBUimnI0QZggEWXZlS23PCI4TcmsJNzD",
            "QSo2Z8kKiC/GwCVYW9isbvO6COBoT0f29nj3en//AD5o//MB" }) },
        { "cono", new Estampa(12, 14, new[] {
            "bczBDQAgCENRmuomLgDp/rMpmnAw/NMjTTA7LVnl0Vtq7RFellbnOD0Racw08pjkHQAO1lPA/jY=" }) },
        { "contMaritimo", new Estampa(40, 20, new[] {
            "zdIrFgMxDEPRUFuRvBCf8f6X13TAFLT5wD4QdI9C3NpXEe0gyaWtpNwFIrTZcuZ4qVz8Xt2UOeYGTzDmnxbvMsnqPnVgFTXKKNjcDajyCATN",
            "sHK4N2HYOkLdcOIu+1vHx71bnMFnb3cwZAzm+wPkZe2oOHQ/ewE=" }) },
        { "contenedor", new Estampa(22, 18, new[] {
            "nc4xEoAgEENRhrGg3mSzVN7/mIKNIhSMv3yTIindSQ7AvaYnI4mQGKNCtSWmdwZSbesfhXWuk8a+IspZtFBNH9D/jtNfmleaD5uVZhva3Mav",
            "qy4=" }) },
        { "contenedor2", new Estampa(22, 18, new[] {
            "jc+5DcAwDENRAUmT0jNwBbIyvP9akexKioqwfPjwYbYHCIDlQYHKDszpJCaOakXOpH6Cd2Q+gaAYXi7bKVnfsNSpQvFD18Gm/ei4Wx0PG71G",
            "ox6fv1kdGit7AQ==" }) },
        { "deposito", new Estampa(18, 20, new[] {
            "dc1RCsAgDAPQBjvyl1Psy/sfcF2l6pDlo9Bng2ZvesZWcpf6BhL2Kyieu4JVgtxjoISE+i04S66giHPeOEmP0FcrhY5DeLSAEgzBVdLio5aj",
            "ZECss4Wh9hHLQkmm7cuP4JCVBw==" }) },
        { "farola", new Estampa(12, 28, new[] {
            "pdCxCsAgDATQkNzh3DVZ/AqX/v9/VaiJUAodetNTD8WIzICSIUMXwQbabXdTP9aBjp4diXOUOTrSBqt9n5G9KAri2/xj7Cub1cM6f1NGvBq7",
            "Y3MOxqyowmtAUHnkAg==" }) },
        { "grua", new Estampa(48, 48, new[] {
            "7VTBCkMhDHuU2i/pYbunJ///v1Zl420Ht4bxbgZBkSTECD2OjY2NvxBB0UUgQtCnf1UxeDe8TgXzt/w/FU9C4LxYS3yJVYvu8N4dmHvMhbxY",
            "hIkYkg/gm3+GlZHcU1apEon5kLg7879V/5MvFB8B0t9J/rXvBZ2nX9wP238n/ak8Nvq3Mls1+0drrcQ20/QHrOWxMk2GIlRzq02gqUhNfcKJ",
            "qDLzsD4LC3gA" }) },
        { "lucernario", new Estampa(24, 16, new[] {
            "lY5RCsAwCENLE+uhhve/1kK3D93awZ7gx0NMWvsApgGMWsie4A16uXe4AJzl3gKHIKL4vvO+8QyVUagKFD8wC/nDgz9zp49497n+Dygi/88U",
            "z6VfcAI=" }) },
        { "marquesina", new Estampa(40, 20, new[] {
            "lZJBDsAgCASNKz5J/v+zAm0PCDR2D27QUZDQ2k/NVAGjQjuHQjvXC8XE9/3hDPEftFQMW81YooRjPV/wlnIsgrcsr+yvBW/5e1IUvEVu6H2p",
            "nI3AEyXcUZu1fx3onWQ10wjUqj7fwDAcCTd9vreKeTRVYbJolKKT6csm8FsX" }) },
        { "pales", new Estampa(22, 16, new[] {
            "hdDBDcUwCANQRmANEAb2n65O/leTpoeiKIeH5agV+U93yzEkNPBcDMi52HxIghtk4uZiJOm8gLjVf9ytZksVqspeC4ulCXXvZjD2rCtPTFxa",
            "UBSVtje4IurICl/LqpH1xyezd+rxJ1gcJu+pkI+5AA==" }) },
        { "papelera", new Estampa(12, 16, new[] {
            "lY7BDcBQCEJJAJf6++9VK7XptZweagQAsE1EOmXG8LClMbTKyoJVO26em2VRL/sPy8PztGPvqGSlwtOOCx9d" }) },
        { "semaforo", new Estampa(10, 30, new[] {
            "Y2BABizMWFgsMBoEwCwmIICyjI1hLCMjGIuFGcYyNYWxTExgLGFhGEtcHMYSEYWy4HYwMDAz43UVBSxmLCwssiBfooQOAA==" }) },
        { "tendedero", new Estampa(28, 14, new[] {
            "Y2CgN5CTAyI5BN8WCBi0bMFsGTkQZFIAAi2gIiZ9fVtbbZicDFCfDANQSgZsgL4BP1ACIscAFFIAyylA5PT5bVGslEfIASWJlQMBwnIM2OXk",
            "GIByssSGCgA=" }) },
        { "terraza", new Estampa(20, 18, new[] {
            "hZBJDsAwCAOR5TsPSeD/zyuGbodKdaQsA7aSmP2J/GK8MLMPdALEIPeMyBKGUSyLCG5rhvKs7nLfgEGs2nuWIkJxVWEv4pHDWAOnQ14xLG6s",
            "TuqKLlK7XJj0mzV+jMNOG3C/8YrFi5nh44dg/zoA" }) },
        { "toldo", new Estampa(36, 14, new[] {
            "ldFLCsAgDEVRUUsGbysWCUIn2f++mggtCE2KFz+TgxBMaSvMpNjpmq6JDLsQGTRERoY+YluXY/AaHwFMxExg2Pbmysizyx1MzVkPqwYGHU+u",
            "qX8GS+XTlLW9f0w3" }) },
        { "valla", new Estampa(30, 16, new[] {
            "5clBCgAgCERRFwMeZvD+10sFIwuifU8YkC+SgNwaSINJ/XBUdTX3qh/U1VYNFlDTK40BNcZWyf5RHgw=" }) }
    };

    public static readonly Dictionary<string, Estampa> Suelos = new Dictionary<string, Estampa> {
        { "acera", new Estampa(32, 32, new[] {
            "Y2MDAVYkEpXPSgCwgwErEonKZyNgPq351HI/+xB3PxvQB6jms9PZ/tH4H1D3s2OPbwA=" }) },
        { "adoquin", new Estampa(32, 32, new[] {
            "nZLbDoQgDESTXqb//8dri0jbJRrtA3CSCowHES+OUVTO4rkQQI9ihZc2hnCwEUyPxWIzDPZuBY3P7zn1c2Xl6MaOY6aBOzbvJxn7TuaLZ96x",
            "78o/+Txv5ufC4zy/78obTJXjvul/JU55txzbpbzBSGw+p35DZip5lRsTdd+v/Dtr9X351xv/2v3zk38t+RN/809f/f9z8t/ew3of2feDf+z8",
            "Z99o76H5fuef6Qc=" }) },
        { "monte", new Estampa(32, 32, new[] {
            "nVKJDcQwCJvCnsT7z3aX8EepqjupBBQIYLsksb+vrZN+xp0y7xfm4Gaxdl7KXC//mrDaRF5WD5uIPrOet43g43LPNt9yNQs8e468Xayy3Vu5",
            "K1C4K5bPAm64OeOGucDoXgtMrjNOwAVszJ7Yo5848TeT4Vzcy+CmDjunpv/ki4f+A+OhP3vfZ/1tP40d7/qjsRRU4NDZ9edF/46Hk0bGs5/0",
            "57v+eNOf57v4C4IIpEf3aJwCf+rPB/0/" }) },
        { "monteRoca", new Estampa(32, 32, new[] {
            "bZMBEsMgCARHBOVF+f/TeodAbKfMaJFNUs/DoapmqkMykAwO1AX1U3w6Krfxkpg3Aj86Ig1uLrLW2uBrn0DdI7F40374QqV5zMl3v9/8zKrb",
            "+/8X94XBiOfITYO7+9l3cWJyauSMB2OhdviZO4znZFOCv2WvExGZsw+RBRJs3Km0BUdM6KUuK36k+DpBbcX3zfcf7hacKvMIsciUXG3LESdH",
            "EUKHHsEQI9w3BjML6QDJeTCv790gX+vY0WOPprzlI7bLQ+dITa6Zbh/l3xc3yWxJ+6symdJIT83shotDn2r7GRjvY4Wm8I2mRl5+VgsFp/OW",
            "+svgDFnJdd4tPuI74/b+vhh1La4av5n6glfbvzbjhtQiW5xm3rxENx9Pl8j7Ylw8zbfgWlZbWjqzEFz1Aw==" }) },
        { "muelle", new Estampa(32, 32, new[] {
            "nZJRDsQgCEQTksf9j7yKVRTbYpcPog44wCBaTNQ8Krs1HKhRUI5XvF1xvB8nV0MTc/bu/IflHHEGsT1wVTfn1LscFbCX3uYxkWNkus6j4ez5",
            "Ng/LT+kJ/fFQzcAJRF7i9FUPOuk/MviYde13bnooYFwFIeZjj1/1l1z/Vsub/nzSX28nzkoe+k/17/vz5/6T9X8jetz/E/1/" }) },
        { "plaza", new Estampa(32, 32, new[] {
            "rZNLDoAwCAWThoQNfq7RsICE+9/NalBj/aJ2M4su5j1oVRF7Hc8xzZJ0rZWTnWlH8/sjUgNiwFSITjFeqY/96b2fi2jKQeR5eM517z/rnRc+",
            "7L/pfeGX2Pxrbzr3A1CdRxTVfRqbf47MP9Ife4nsP8f98Of7+7D/Av38/0J+rvMM" }) },
        { "via", new Estampa(32, 32, new[] {
            "nZNrEoIwDIQnzwPkJ/c/qJsm2CIgjmXQWaj9drfV3dXVlN3M3BxD8IRLmfMY1Pc6SrtzaJCw4RbI1GQsAq0BjYVq/Vo9hxqrvbVc8fUvfnzw",
            "+YJvxffv/Pv825nPzdeZn5MvW/Hlgj/z6/RnrcGvmcWPx/x62f/oY/Ds0D+k2WN+u+8/jnxqvi79ZydKe//gZ+IuQA/8nDLy++pvaoYJvA+Y",
            "otbZT36RDyMELxHtCx9prbXn1Ow/HeBCPPw0+5fWN/lL2zl/9DGIPX9m1Xn+gk/9H/e/8+vd/q/8384/nc/f0/9vT/sC" }) },
        { "viaV", new Estampa(32, 32, new[] {
            "pZJbEsMgCEVH5LIAPrP/hRauqGn6SGeaySmgTaIezMQsyTDzd3yYhwziXvkTLhqTHY15t6gzFmoaD/Z6f+YXtIl2CZogc3VnrT5AaxgIdr6J",
            "P6uq8Eb8JBwr5OaKTeTGYu1mMz8zvyPusb7X73NvXZD7Q8ZZF3FGRMd54co+H9jKZ+R4THg8780ysq4xxj/93s7TsXMpbALu46B71ulZ6Hr5",
            "txEH0/UX/4mUf1Q9QToANQEhadXFnd90kmiEnQuqP7IObwf90wnrctdHz2lzdF/9Zxf/mP5t+1/87t+evc8z8pP/xtzsOPXA8IRP/h4=" }) }
    };

    public static readonly Dictionary<string, Estampa> Iconos = new Dictionary<string, Estampa> {
        { "aviso", new Estampa(24, 24, new[] {
            "hZJBDoAwCAT7mCb0AeXG/98l0EKxYNyDh2FnjYmt/YQkFUfE4kCEAPmgWA5pBWCMJEh9ML8FfqnwW1h1Ij2kdeUQhL0u/LVEfR4+O3m9T9Sv",
            "lSdzchy5CYY3N8FWPFvwuvWXEOrORTj1sMRCyeXAPEeFIvriKp+/xwM=" }) },
        { "bate", new Estampa(24, 24, new[] {
            "jdHBCQAxCERRIZ3IDGsR9l/XmrAnnYV4fPlIQLPbyT2KH2I+FAfhKTgedj9Msu356smh6xNfMxhbO1fq5TYY7imWHO41gBHvn3DGxWtFSlax",
            "ZEtItnS6PJtLNn3k/3kB" }) },
        { "botellin", new Estampa(24, 24, new[] {
            "tdLBCcAwDANAz2CtkIcX8Mdo/7lal35KlFAo1fOwQ1Bidocdm8PMIb1WXpAOKOdinr5zanfOx6PUQo+rBdbleO0eETm0R/7rmfh+/y7C5x7o",
            "53s5RaHPj3IA" }) },
        { "botiquin", new Estampa(24, 24, new[] {
            "Y2CgDrDBBayxAgrEjYyMKBc3ggEKxanlHiqGD5q4Dbu1NRsKsLZmt7HBEWEkxzsA" }) },
        { "bus", new Estampa(24, 24, new[] {
            "zZDRDcAgCEQNE3SDm4H74Mv95yqntprUfrcXQHgkxrOUr1R3Ej+eykWtdKfSZ3pyRgRVUmgRbBydi0ERSJ7XACA5sh/JudML987NFpaD3lOh",
            "1lZu7tbMZTudGuwyLHz/yhzGejP8SCc=" }) },
        { "camisa", new Estampa(24, 24, new[] {
            "3Y/BEYAwCAQpJVXcfei/LnNAMjGMDbgv2dUEzQJf2IFmjOBM7iShAIDcQXp6yOuxQryeH6TPIJ3jGCwU4vDL0+vS5muX02OHy+euMzRfC91+",
            "/UDz9vLFf3zDvnkA" }) },
        { "cargador", new Estampa(24, 24, new[] {
            "Y2AAARsQgJIIAOQxMQnCSYSwoKCkpKAgoyAQSArCJWwEmZGBIDHiVsxWEIAsLkm6OaPiVBS3kQQBRjCJFL+Q9IEAYDEA" }) },
        { "contrato", new Estampa(24, 24, new[] {
            "1dExDgAhCERRAoXcibn/uZSsG8BIucX+yrzRSqIdVnQJIseAJ/EB6ZlLLtzMtvmpePQ/569dGx/dfe08DVz8XVST11D/PXKc" }) },
        { "deportivo", new Estampa(24, 24, new[] {
            "1ZHRDQAhCEMhbNBN4Jv95zohgF6cwCYa+opGItFr8tJFLXWkWZhJiCsi707V2PYh0RVoK3NdaC3Ah5cLzizYHOniCly83oQuxs1A//Ee+o0P" }) },
        { "diana", new Estampa(24, 24, new[] {
            "lVLBAQMhCHODu1map+w/V4+EKLX9NB+BgGBwDCIWRsPjvgqd2VExPTwFbCLDmAsmMnxXJvkiYnlEEUyn7evpxPgIl8Vp00CVQyaSUEI1uJ4T",
            "Ktjx/2xoSvR7pjp6surLgltjXk5f78L0kemnDjKpj1W22JTnkP9rAWaOhUVfY/xY/PEh9kex/wY=" }) },
        { "energia", new Estampa(24, 24, new[] {
            "ddLBEcAgCARA6zgesQs/139dgWhGxZPnDt6AWsosehVRBJSTVbmz8mDhJLQHu6eRvhR3pCNEC29t99HunLyOemzN53TdXu0Sg21MmgFHer9I",
            "BKd9Y0scKf89HO3dg5VLDpePe3lb98tfSPwC" }) },
        { "escopeta", new Estampa(24, 24, new[] {
            "1Y/RCcAwCERVnMTfcwT3n6tnQouhC7QPCeHJoYp8lhocWhfOGg1q93ZuZj6igC9gmdrhzARfwLZHBDqNhq0yLX3iywer//oMpI+GXuaC21fp",
            "sfP2r1PuI+W/XA==" }) },
        { "estrella", new Estampa(24, 24, new[] {
            "dZLLAYAwCEM7Tq+08cb+cxmgH9Sa4wtgoJYypVT5SlXkyAX90KAK9K6n8np9G6yc/NXAJCyvlzWMFnWJIHhnqIHgqtU4DRfN1pwN7oomGsg4",
            "ZjGgGcCEA9v+bhDCVhs4GXA+cRhYkr1zcBttfF/VI0XwF5+YxpPb96iIs67WnNqZaG0ubV9Lcr2k6+b56Zl+/oqlGw==" }) },
        { "estrellaOff", new Estampa(24, 24, new[] {
            "dZJBEsAgCAOdnHhU/v+uUsEalObSmSVB0I6xRNe4RQIth6EJkGZdwO3WBF77HfBJXvsMZIRTCOwBgIlMhdS21iLvQth9QC2sLrE/Ko+RSmHj",
            "KEinvXNwID+Vx4kH3wsdHCLKS63dC9fbqn65Xe0vz/TzV3x6AA==" }) },
        { "euro", new Estampa(24, 24, new[] {
            "dZLJEcAgDANdTYYCpB/031biM4ZM9GJWvsCIuGZIuhQM02YFBMIqvNZSRhKvodEeaQ7D6DgMqjHHJuOc2dN0wROMN9wLfcuocPDExnU0vxca",
            "z+MPZxU5OA/eErLxeLC0hKdFhkvjRGHlzYgqmP7OrAEtGrUA1Oh4cRqhfcFpnT/i809u" }) },
        { "fuga", new Estampa(24, 24, new[] {
            "bZLRFcAgCAOdI6Pwsv9cLahokHweJAXsGCmGRhWJX2+BsF9g7e44I+ThTs0mpmDbEn7wnRPtWTtLOAKPA8tDZjsky50rpMy6OEg90vXV5jZS",
            "mEY888d1EQTKr4Ua7qBw7OE4R935FG9eoa7RPH08fPdLJP0A" }) },
        { "furgo", new Estampa(24, 24, new[] {
            "zY/bDQAhCAR5hK7W/ttSxMspWIDzN5OsEaIHQWHllsA9Nx94FpE8mFm1DOoj0e2W1TuOUQggArO9DxvNMeP/Ig7xf/J3IB2GLWd7hg4=" }) },
        { "gorra", new Estampa(24, 24, new[] {
            "rZFBEoAgDAO58pyk1/z/XVLraCl40lwYNqEwobUP0tCOCSjW2JkLZj07QS/129DEDdrFSWqNg87DEKY0iZUjcyv5uEDLHOdSfY3PKfThwMqj",
            "KkwnFM2di5jwps3U2O2MI3z7FrXfdQA=" }) },
        { "hambre", new Estampa(24, 24, new[] {
            "xdJJDgAhCARAjjyq+f+3RhpxQTNXubQpjcFFRARRfSCjoF5ozDidgerI+ep6uJn9OIw5HWTO694ol7WdbOV0z5Vf+61PXxjneuCojrhebM8b",
            "P6VH8gc=" }) },
        { "libro", new Estampa(24, 24, new[] {
            "rZExDoAwDAM7O4nymKz5/7twKAWB6ICoh8i+eHNr35Rdz5wJcffjV9cYBZlavPyAlCq5du8hEf7GY8Lxs3/0Bme0wXchTjfhtpCb4cndgn0T",
            "EfjgCsbqoxsFDUSFNdpzBdSDJ29D5aW2Vhs=" }) },
        { "llave", new Estampa(24, 24, new[] {
            "vZA7DsAgDEM5S5QlO97C/a9VzCctSmcsBvQcOZ9SrsqXEhUxQE6j04YKaDd+MOUHxpb5gYfBoMj3WV35NNr6iFYyvHhSqCmprumD8mPmUUyK",
            "UfXddA+XVpcK6wu2dBJTE6aXbHjG+7Tlsh4=" }) },
        { "llaveInglesa", new Estampa(24, 24, new[] {
            "lZHRDQAhCENFYAHn6f5zXfW+tJjc9fNBmkJb+ypMVdjddUBssECxncgBwRnqAwTlXXBmRIdiLpvQaeJDsOfV2nHDxzvgsYLsm5k8Zd9u6xJa",
            "nPnIbQ4kHxPb4kUL5MXH3yxakFFFc7gU+k8P" }) },
        { "lonja", new Estampa(24, 24, new[] {
            "pZBBDsQwCAMr3/mDJS78gfz/XWto2m2UnnY5IGWMHcnH8eOMORsHwgJjuyaN5OLQw5iZcAcuoUKJwkloRVu0IuQXwelw2mjaEQmyFpL0kOLh",
            "KSKKMwy6LG4eaEunZ9HmmgDmBw1vLsXu04VL+cKFP6l5//siVAMb71prPfmj61O46Nqy73RaXuhs+/hjPg==" }) },
        { "meta", new Estampa(24, 24, new[] {
            "dZJREsQgCEOdEBgOxf3PtYC21d0uH532GSTGRkSMlwr1GDHr4EASVh0rAQszdwPULl7NUMKbp6I78qkRIri5Ws8xkdwaDwcoOQhYXLsHvWaO",
            "5gpRdE/hxdOb0v2bM+eqP9zYnH5xirC4Wb2kpDnXuYrnzMU3/5xc8eM/Rbt/VSFO//mtM2bT3T8rrhnirWdHf8WeGU5epPIfT+x5kLzAGAcf",
            "24WefFMY3/mf/+QD" }) },
        { "metro", new Estampa(24, 24, new[] {
            "bZJBDsUgCES9x8TAGWDL/c/1kSpgf9+iKW8aY0fHWFhjJD5oUomZaEN24JpVp+NPVT6BkUAjwIoUQo9nUSogwseDCw++PJWfzcdC88/T289j",
            "m8f2uSGU59k2ml6Zgdp/eW8Fp570fNXW/9fLSvjq4du/2J5W9xPF9nj7fS5mMa3MwtYBx2TPF/eFsLov8fYD" }) },
        { "movil", new Estampa(24, 24, new[] {
            "Y2AAAhsUwAAHNswgwMQExMxMGOJgOWZmFHEzOKC1ONNQFGeiujgTqjgSwBAHxSRWcRzqsZiDmU4A" }) },
        { "mudanza", new Estampa(24, 24, new[] {
            "xdKxFcAgCEBBpgE6BwD3XytKQAXThy73fRZBAB+dA3WGMXMtr7KVxCKygh6HRa7iV+QynfxrF3w9ghfEcOo7tHZ6j8LV7TbElpym0wA03m6D",
            "a351vTx+qCZPG1iuZWNqfq9+BPx6EFCeyQM=" }) },
        { "obra", new Estampa(24, 24, new[] {
            "rZDBEcAgCAQpxwLCj/TfViBwgyh+MtmX7nFjAtE3xNk1G0ui18FDqYnawDtF3/AIclq9N9xzKMxHAZ6hvWBfmKOTf08nX7EHOq8F6f2irwyY",
            "+8JBi+xR7BR/ho1OC63Qjzw=" }) },
        { "ojo", new Estampa(24, 24, new[] {
            "bZLRDcAgCET9YolLjHvI/nOVQ6Vge4kfvAOiYGtLutQuqYK6HcPThWIErkbCxciYRqTPyvUvPQpWOjqFzBF4O6uR8955qCggB2Ogj8GClzOP",
            "cximi/t88OEDkS+pv8WbI/M5QlNk35PvwsEQ42kOy7AmImdwqiL+fvMdvwO1UBxm7IsRObQu8n/v33/yAA==" }) },
        { "ojoTachado", new Estampa(24, 24, new[] {
            "bZJLEgQhCENpVh6K+59rDNEYuycLS54UXyOootY1QjghoKqnDI8WXh5xYTxMXB88xsFx4zxRHCPFx31ipDD3LrOxeB48j2ms9sg7JXmKwwam",
            "w8V3kJc/g+SbOzaOAndS46xb2mtA85onOPti86JnDmtuqubfQA37YtKX3rG091v2T1o/" }) },
        { "pantalon", new Estampa(24, 24, new[] {
            "jZLRDQQhCEQN3JSBlUz/dR2irqiby82HhCeMBi3FxayyRAAKMfW4cRUVfKSFjXsu5lKzbNTqLQTJRuwwWuzm9sJrDRucHLXZ+Jo4O9eLD4fm",
            "VtNFe/nkxuPYYWdnPef+C8e/HLcPxxieuE+Ha3/n5WhY2W8+n5Lh3DLGOzJPNLL0T74=" }) },
        { "pintxo", new Estampa(24, 24, new[] {
            "dZBLDsQwCMVyFgRiH6m7d/9zDR/RoS3x0nFJylodOOsLeNPsmUdPdJgzj8EpxykfJDA8BtjwMa//Mr038WW0A4vUvWoe4B+74fAqdbvP8NC/",
            "UUNQ+ZWkl3wVIBFHb5ole0jcpok4zYdkluZJrHLJL0/ERerJ35t4+LYe2y6VeywNRV/kDw==" }) },
        { "pistola", new Estampa(24, 24, new[] {
            "rZDBDcAgDANJvUHm8f5zNQiiKsVUfXAvchgFubVjMBAjJUr78AAuB2JEkt4dhf4KgunNbBzLGnj68uG4CC80exw6vuQf/S5n+qU0+/DcelU+",
            "+d+f4gY=" }) },
        { "plato", new Estampa(24, 24, new[] {
            "lZI7FsUgCETtxmaWY4Xsf1vh84jE7k3hiXcIIjhGaJdGl+0xQ92yz9lUxpceIzEAEeAYb7iYbCmj41AYFS5yc1UtvtayFVnu4WulkScYB8nG",
            "5U+OzhlxHs1581PnryB2g3lh5x9D415jozLRDqTvsj9puOOJNXj23w37xbqpkbQGkEaJ7yT35iyKPnufts8KuF/EuN/JAw==" }) },
        { "prohibido", new Estampa(24, 24, new[] {
            "lZLBEcAgCAQdKrAUBp6h/7oCSCaI5JF97uVGA46xkGBkTICzJSY5SIlqTkAErhFrEBq3hnnVE3EmT1ZwP7Nm0oIIV4hIyl0er0cD8bXzePrr",
            "6csf2JQ6rz/WFWwQXWENDrrPfaDHoaMJIC3sTeqGu7137+QG" }) },
        { "puerto", new Estampa(24, 24, new[] {
            "lZBLCsAwCEQD0p14gaE3mfufq5o05A/tbGIeOn5SGkRXWuTQjCskXNxAos+vMJ7GazkLx9uZVJtUOGzPo1qLjdsp2ga129i38T76kh/+W24H",
            "jn/+p3kmHnsaOUSZa1wuvn4QtZriB43xLEeKXBET3K5rkh8PgltEFn7QAw==" }) },
        { "punos", new Estampa(24, 24, new[] {
            "tZBLCsAwCERdFwSP4TIHMPe/Vv3FmlDoqrNxfDOBIMD/EtObZR6SngdHYlTVvS9pw4+1VMWC5kHIJqlQxAZlpzgJLq4+OnTR1D5OQvLUObr0",
            "bRg8OGSw9/2f0vuFW7D4c5SD1w2/eGq7edv/0g0=" }) },
        { "recado", new Estampa(24, 24, new[] {
            "rZLBDcAgCEUZgANLEDw5AfvPVWxVhGrSQ9/xgZDwBQDNwIOWAL68GAV5egm4V3YEfb6OGQ3G/V7mX7ytHouz7w/05MvBy6Lli/eCRC/znMkv",
            "19x7Ht5ii/1owTSoGu7RIKK7VBM9ez19iB0X" }) },
        { "reparto", new Estampa(24, 24, new[] {
            "lVHRFcQgCHONDMAA6C/7z9UErD7v/GmebWmAGKW1j4gXv7wV4i258Aiuk/esx244dOA24qYzhl3rw//4xBhLH0ZZd0Cb+kqweYG8vQkVMeVa",
            "DJnw4tnae+fjKhHyDIGecPJNPOM00Tcfk1cIumGgfyBFyln50bu0pzNtABimXX1i81jTiaJjHmyPoy57TfKca/uMBw==" }) },
        { "taxi", new Estampa(24, 24, new[] {
            "3ZLBDQAhCAQJoQrePmiA3/Zfl4ImF5EKbhI/g0RcJdrgQDfASEoB8E0pYLibWRaKt+R/Pu87vOTw5dPm2QXNzI+NZ0mPZre8HWARYV2rzBM+",
            "WB2XVz5omR+aNCff/2QC" }) },
        { "tren", new Estampa(24, 24, new[] {
            "zZDRDcAgCERN2IDLOc3tP1cRxWq6QN+P+AIItvYLFBzhi9n2feIRXB4U2QkYwqM6SaEA9mJWKPJvlq8rLAE8G23vBUZBdKciQ6lyUl8DR4Bq",
            "wiHc1i5y2n7UhtBn33ncv3Kov/EA" }) },
        { "uzi", new Estampa(24, 24, new[] {
            "xZBLDsAgCEQd4ALch/ufq4zYNlYX3TQdEyJP5Nfa1wrqAbpFnkkSxKoCOFAmoA5yWcTvLbQcUzs53DMZBreLixqr4NbIE8V5IwrvMdXTKAyY",
            "nW2OKRKmo+YxjyvVVsZv1rDyWseG1yN7frPUv3QA" }) },
        { "zapato", new Estampa(24, 24, new[] {
            "pZLLDcQgEEORc3QV08EU4P7rykz4hMDuYTfvANLDYxGFUl6goG6Ld88j+erplT3/g8/ipvXQ9A8+0uwHpjkt0C5NjoG8NWOg0Qeyg8Ybjeon",
            "uhqMm9+j3zSCqFmsoXnM5YgC5FJyx8iq0r9IOAKs/0mD/5/ACQ==" }) }
    };

    public static readonly Dictionary<string, Estampa> Marca = new Dictionary<string, Estampa> {
        { "logo", new Estampa(64, 64, new[] {
            "nZdtcoQgDIY7uYFMGE7iL7z/uZpPDCiom0633V2eNy8BNfz9TWP3+PshmDs0fpAweONQiW+Zd4EB+BdY4v08zDaRmwUp+DzepRbIUGhvnivh",
            "qQ0S4/aPvVuYuKTW8edURGZiwlfLUvuU+1KeoqOCw11qzTMoBBOR13kOKfY9bKKwJCbf8adBg33rHUel0P/OytKwgb9MGin4ba0qQF9EExf+",
            "hOUDLFgKOu4ewq6+4X1leBynh46vzdqUD6tB2Sl/jXy1oi54L3mtWDbmJQr9tCKseC97FZ5eGp+FF4kVL2jjy8C7iSl/lgslIF35uuLbICyq",
            "8ok/Ik+QFDC95uNSSWLiERN85gG88pgSepwKDzwAUUWCsicpRWGtlzx2QQYK8wiA8MRb2iHYvLyahRmP97gqhP0w4bHkC5j70CpO+DxJ3iss",
            "+DxT6CUWfC+Rb/mUJnxKppAZKC5nkgbTDOY8mkLuEha3xblpzJTnFbrhlaZX4BFp4Z+/zpDvI6HhK/+IOU3wJCz/mfIWHQcaCTPzsokX8zc+",
            "NVY2bJaLSvG5f7ve1CPBejH7ugmel/NHuV0Ij4qD45g1+bp+mlslQvKsnJt7qp9NNZi3T9/xXga+WYDjgZ7wQcCHtwqkk6XQHuamf9jCICHo",
            "IVCh0I0vfOFtytV/p2BLUYo8iKCj5Vkz9E/HKKB15IdIELBB29BRW1dxUeDJysVvCht4lzS2kPu9BePFhPfT903sfq8A1fhSvfGatcA6iSjA",
            "l0+7BcKJL/tvV5Dnb/Hs9unDUaSr44Ten08fQUA8tMK9OMMEC5taeGe9t7DpSnf461OcN/yyVz4mj3vBzzKfkt8sxMfzY5iE+P+cvLPwU/J4",
            "qtp/xf0Avx7zDw==" }) }
    };
/*ARTE>>>*/

    /// <summary>La pieza de una familia, o null si no se trajo. El juego nunca depende
    /// de que esté: quien pregunta tiene que saber forjarla.</summary>
    public static Estampa De(Dictionary<string, Estampa> familia, string nombre) {
        Estampa p;
        return familia.TryGetValue(nombre, out p) ? p : null;
    }

    /// <summary>La pieza como lienzo, al tamaño pedido y por vecino más próximo.</summary>
    /// Un singular se dibuja a la medida que le haya cabido —el plano pide treinta y
    /// cuatro casillas y a lo mejor caben diecisiete—, así que el aumento casi nunca es
    /// entero. Copiando píxel a píxel no sale ni un color que no estuviera ya en los 61,
    /// que es justo lo que haría cualquier remuestreo con filtro.
    public static Lienzo ComoLienzo(Estampa p, int w, int h) {
        var pal = Paleta.Lista;
        var L = new Lienzo(w, h);
        var px = p.Px;
        for (int y = 0; y < h; y++) {
            int sy = y * p.H / h;
            for (int x = 0; x < w; x++) {
                int v = px[sy * p.W + x * p.W / w];
                L.Px[y*w + x] = v == 0 ? new Color32(0,0,0,0) : pal[(v-1) % pal.Length];
            }
        }
        return L;
    }
}

}
