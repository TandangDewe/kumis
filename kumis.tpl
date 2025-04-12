<html lang="en">
    <head>
    </head>
    <body>
        <p>Kode Pos {{country}} ({{code_id}})</p>

        {{?post_code}}
        <table>
        <tr><td>Angka Pertama</td><td>Zona Pos</td></tr>
        {{#post_code}}
        <tr>
          {{>table}}
        </tr>
        {{/post_code}}
        </table>
        {{/post_code}}

        <p>{{=|| ||=}}Made by {{Kumis}}</p>
    </body>
</html>