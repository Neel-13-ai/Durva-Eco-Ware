# Backend API Issue: PUT & DELETE Returning 405

**Target:** `https://api-dev.durvaecoware.com`  
**Swagger:** https://api-dev.durvaecoware.com/swagger/index.html  

---

### Issue
Edit (`PUT`) and Delete (`DELETE`) requests return **`405 Method Not Allowed`** across modules:

| Module | Edit (`PUT`) | Delete (`DELETE`) |
| :--- | :--- | :--- |
| **Suppliers** | `PUT /api/suppliers/{id}` ➔ **405** | `DELETE /api/suppliers/{id}` ➔ **405** |
| **Units** | `PUT /api/units/{id}` ➔ **405** | `DELETE /api/units/{id}` ➔ **405** |
| **Warehouses** | `PUT /api/warehouses/{id}` ➔ **405** | `DELETE /api/warehouses/{id}` ➔ **405** |
| **Categories** | `PUT /api/categories/{id}` ➔ **405** | `DELETE /api/categories/{id}` ➔ **405** |

---

### Cause
The IIS server on Plesk has **WebDAV** enabled, which blocks HTTP `PUT` and `DELETE` requests before they reach ASP.NET Core.

---

### Fix
Add these lines inside `<system.webServer>` in `web.config`:

```xml
<system.webServer>
  <modules>
    <remove name="WebDAVModule" />
  </modules>
  <handlers>
    <remove name="WebDAV" />
  </handlers>
</system.webServer>
```
