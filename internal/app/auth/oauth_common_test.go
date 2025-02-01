package auth

import (
	"encoding/json"
	"testing"

	"github.com/h44z/wg-portal/internal/config"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func Test_parseOauthUserInfo(t *testing.T) {
	userInfoStr := `
{
  "at_hash": "REDACTED",
  "aud": "REDACTED",
  "c_hash": "REDACTED",
  "email": "test@mydomain.net",
  "email_verified": true,
  "exp": 1737404259,
  "groups": [
    "abuse@mydomain.net",
    "postmaster@mydomain.net",
    "wgportal-admins@mydomain.net"
  ],
  "iat": 1737317859,
  "iss": "https://dex.mydomain.net",
  "name": "Test User",
  "nonce": "REDACTED",
  "sub": "REDACTED"
}
`

	userInfo := map[string]interface{}{}
	err := json.Unmarshal([]byte(userInfoStr), &userInfo)
	require.NoError(t, err)

	fieldMapping := getOauthFieldMapping(config.OauthFields{
		BaseFields: config.BaseFields{
			UserIdentifier: "email",
			Email:          "email",
			Firstname:      "name",
			Lastname:       "family_name",
		},
		UserGroups: "groups",
	})
	adminMapping := &config.OauthAdminMapping{
		AdminGroupRegex: "^wgportal-admins@mydomain.net$",
	}

	info, err := parseOauthUserInfo(fieldMapping, adminMapping, userInfo)
	assert.NoError(t, err)
	assert.True(t, info.IsAdmin)
	assert.Equal(t, info.Firstname, "Test User")
	assert.Equal(t, info.Lastname, "")
	assert.Equal(t, info.Email, "test@mydomain.net")
}
