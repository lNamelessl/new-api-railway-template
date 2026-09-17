# new-api (QuantumNous/Calcium-Ion) LLM gateway — Railway template image.
#
# AUTO-BUMP: the weekly-bump GitHub Action rewrites the version in the FROM
# line below to the newest upstream release that has a matching Docker Hub tag.
# Keep the "FROM calciumion/new-api:" prefix intact for the bump script.
FROM calciumion/new-api:v1.0.0-rc.37

USER root

# netcat for the wait-for-dependencies loop in the entrypoint wrapper.
RUN apt-get update \
    && apt-get install -y --no-install-recommends netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint-wrapper.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

# Base image facts: WORKDIR /data, EXPOSE 3000, ENTRYPOINT ["/new-api"].
# We clear the entrypoint so our dependency wait runs first, then exec /new-api.
ENTRYPOINT []

# In-image healthcheck (Railway uses its own healthcheck config; this helps
# local docker runs and self-hosters outside Railway).
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=5 \
    CMD wget -q -O /dev/null http://127.0.0.1:3000/api/status || exit 1

CMD ["/entrypoint-wrapper.sh"]
