VERSION=${1}

if [ -z "${VERSION}" ];
then
	echo "Usage: ${0} <version>"
	exit 1
fi

git tag sort-media-v${VERSION}
git push origin --tags
