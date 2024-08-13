import boto3
import sys


def delete_bucket_contents_and_bucket(bucket_name):
    s3 = boto3.resource('s3')
    bucket = s3.Bucket(bucket_name)

    # Eliminar todas las versiones de objetos y marcadores de eliminación
    print(f"Eliminando todas las versiones de objetos en {bucket_name}...")
    bucket.object_versions.delete()

    # Eliminar todos los objetos que no tienen versiones
    print(f"Eliminando objetos sin versionar en {bucket_name}...")
    bucket.objects.all().delete()

    # Eliminar el bucket
    print(f"Eliminando el bucket {bucket_name}...")
    bucket.delete()

    print(f"El bucket {bucket_name} ha sido eliminado con éxito.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python script.py <nombre_del_bucket>")
        sys.exit(1)

    bucket_name = sys.argv[1]

    try:
        delete_bucket_contents_and_bucket(bucket_name)
    except Exception as e:
        print(f"Se produjo un error: {str(e)}")
        sys.exit(1)
