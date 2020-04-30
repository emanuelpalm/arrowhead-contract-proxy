package se.arkalix.core.coprox.security;

import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Objects;

public final class SignatureScheme {
    private static final List<SignatureScheme> ALL_SCHEMES;

    private final String ianaId;
    private final String javaId;
    private final String algorithm;
    private final HashFunction hashFunction;

    private SignatureScheme(
        final String ianaId,
        final String javaId,
        final String algorithm,
        final HashFunction hashFunction)
    {
        this.ianaId = ianaId;
        this.javaId = javaId;
        this.algorithm = algorithm;
        this.hashFunction = hashFunction;
    }

    public static final SignatureScheme RSA_PKCS1_SHA1 = new SignatureScheme(
        "rsa_pkcs1_sha1", "SHA1withRSA", "RSA", HashFunction.SHA1);
    public static final SignatureScheme RSA_PKCS1_SHA256 = new SignatureScheme(
        "rsa_pkcs1_sha256", "SHA256withRSA", "RSA", HashFunction.SHA256);

    static {
        ALL_SCHEMES = List.of(
            RSA_PKCS1_SHA1,
            RSA_PKCS1_SHA256);
    }

    public static Collection<SignatureScheme> all() {
        return ALL_SCHEMES;
    }

    public Signature sign(final PrivateKey privateKey, final Instant timestamp, final byte[] data) {
        final java.security.Signature signer;
        try {
            signer = java.security.Signature.getInstance(javaId);
        }
        catch (final NoSuchAlgorithmException exception) {
            throw new SignatureSchemeUnsupportedException(javaId, exception);
        }
        try {
            signer.initSign(privateKey);
            signer.update(data);
            return new Signature(timestamp, this, signer.sign());
        }
        catch (final Exception exception) {
            throw new RuntimeException(exception);
        }
    }

    boolean verify(final PublicKey publicKey, final byte[] signature, final byte[] data) {
        final java.security.Signature verifier;
        try {
            verifier = java.security.Signature.getInstance(javaId);
        }
        catch (final NoSuchAlgorithmException exception) {
            throw new IllegalStateException("Signature scheme \"" + javaId +
                "\" unexpectedly unsupported", exception);
        }
        try {
            verifier.initVerify(publicKey);
            verifier.update(data);
            return verifier.verify(signature);
        }
        catch (final Exception exception) {
            throw new RuntimeException(exception);
        }
    }

    public String algorithm() {
        return algorithm;
    }

    public HashFunction hashFunction() {
        return hashFunction;
    }

    public static SignatureScheme valueOf(final String string) {
        switch (Objects.requireNonNull(string, "Expected string").toLowerCase()) {
        case "rsa_pkcs1_sha1": return RSA_PKCS1_SHA1;
        case "rsa_pkcs1_sha256": return RSA_PKCS1_SHA256;
        }
        throw new IllegalArgumentException("Unsupported signature scheme: " + string);
    }

    @Override
    public boolean equals(final Object other) {
        if (this == other) { return true; }
        if (other == null || getClass() != other.getClass()) { return false; }
        final SignatureScheme that = (SignatureScheme) other;
        return ianaId.equals(that.ianaId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(ianaId);
    }

    @Override
    public String toString() {
        return ianaId;
    }
}
